from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import VPC, ALB, Route53, NATGateway, InternetGateway, ElasticLoadBalancing
from diagrams.aws.compute import EKS, EC2
from diagrams.aws.security import WAF, ACM, IAMRole
from diagrams.aws.management import Cloudwatch
from diagrams.aws.storage import S3, EBS
from diagrams.aws.database import Dynamodb
from diagrams.aws.integration import Eventbridge
from diagrams.k8s.compute import Deploy, Pod
from diagrams.k8s.network import Ingress, Service
from diagrams.k8s.infra import Node
from diagrams.k8s.ecosystem import Helm

graph_attr = {
    "fontsize": "28",
    "bgcolor": "white",
    "pad": "0.5",
    "nodesep": "0.8",
    "ranksep": "1.2",
}

with Diagram(
    "EKS Express - Production Architecture",
    show=False,
    filename="eks-express-architecture",
    direction="TB",
    graph_attr=graph_attr,
    outformat="png",
):

    # --- External Entry ---
    users = Route53("camicamp.com.br\nRoute53")
    cert = ACM("ACM\nSSL/TLS")
    waf = WAF("WAFv2 Web ACL\n8 Rules\n(Geo, Bot, SQLi, OWASP)")

    # --- Terraform State ---
    with Cluster("Terraform Backend"):
        s3 = S3("S3 State\nVersioning")
        dynamo = Dynamodb("DynamoDB\nState Lock")
        s3 - Edge(style="dashed", color="gray") - dynamo

    with Cluster("VPC 10.0.0.0/24 (us-east-1)", graph_attr={"bgcolor": "#E8F4FD"}):

        igw = InternetGateway("Internet\nGateway")

        with Cluster("Public Subnets (2 AZs)", graph_attr={"bgcolor": "#D5E8D4"}):
            alb = ALB("ALB\nInternet-facing\nHTTPS:443")
            nat_a = NATGateway("NAT GW\nus-east-1a")
            nat_b = NATGateway("NAT GW\nus-east-1b")

        with Cluster("Private Subnets (2 AZs)", graph_attr={"bgcolor": "#FFF2CC"}):

            with Cluster("EKS Control Plane - K8s 1.34", graph_attr={"bgcolor": "#F8CECC"}):
                eks = EKS("eks-express-cluster\nOIDC / IRSA\nAPI + ConfigMap")

            with Cluster("Managed Node Group (Bottlerocket)", graph_attr={"bgcolor": "#E1D5E7"}):
                node1 = EC2("t3.small\nNode 1")
                node2 = EC2("t3.small\nNode 2")

            with Cluster("Karpenter Dynamic Nodes", graph_attr={"bgcolor": "#DAE8FC"}):
                karp = EC2("t/m families\nGen > 2\nOn-demand\n8h rotation")

            with Cluster("kube-system Add-ons", graph_attr={"bgcolor": "#F5F5F5"}):
                lbc = Helm("AWS LB\nController")
                karpenter = Helm("Karpenter\nv1.9.0")
                ebs_csi = Helm("EBS CSI\nDriver")
                metrics = Helm("Metrics\nServer")
                node_exp = Helm("Node\nExporter")

            with Cluster("external-dns namespace"):
                ext_dns = Helm("External\nDNS")

            with Cluster("Workloads (nginx-sample)", graph_attr={"bgcolor": "#D5E8D4"}):
                ing = Ingress("Ingress\nALB class")
                svc = Service("ClusterIP\nService")
                deploy = Deploy("Deployment\n3 replicas")
                pods = [Pod("nginx"), Pod("nginx"), Pod("nginx")]

    # --- Observability ---
    with Cluster("Observability (Managed Services)", graph_attr={"bgcolor": "#FCE4EC"}):
        prometheus = Cloudwatch("Amazon Managed\nPrometheus\nScrape: 30s")
        grafana = Cloudwatch("Amazon Managed\nGrafana\nSSO Auth")
        cw_logs = Cloudwatch("CloudWatch\nLogs")

    # --- IAM ---
    with Cluster("IAM Roles (IRSA)", graph_attr={"bgcolor": "#FFF3E0"}):
        iam_lbc = IAMRole("LB Controller\nRole")
        iam_dns = IAMRole("External DNS\nRole")
        iam_karp = IAMRole("Karpenter\nController Role")
        iam_grafana = IAMRole("Grafana\nWorkspace Role")
        iam_ebs = IAMRole("EBS CSI\nDriver Role")

    # --- Connections: External traffic flow ---
    users >> Edge(label="DNS", color="darkgreen") >> waf
    waf >> Edge(label="Filter", color="red") >> alb
    cert - Edge(style="dashed", color="orange") - alb

    # --- Connections: VPC flow ---
    alb >> Edge(color="blue") >> ing
    ing >> svc >> deploy
    deploy >> Edge(style="dashed") >> pods

    # --- Connections: Network ---
    igw >> Edge(color="gray") >> alb
    nat_a >> Edge(style="dashed", color="gray") >> igw
    nat_b >> Edge(style="dashed", color="gray") >> igw

    # --- Connections: EKS ---
    eks >> Edge(style="dashed", color="purple") >> node1
    eks >> Edge(style="dashed", color="purple") >> node2
    karpenter >> Edge(label="provisions", color="blue") >> karp

    # --- Connections: Add-ons to services ---
    lbc >> Edge(style="dashed", color="darkgreen") >> alb
    ext_dns >> Edge(style="dashed", color="darkgreen") >> users

    # --- Connections: Observability ---
    node_exp >> Edge(color="red") >> prometheus
    prometheus >> Edge(label="data source", color="red") >> grafana
    prometheus >> Edge(style="dashed", color="gray") >> cw_logs

    # --- Connections: IAM ---
    iam_lbc - Edge(style="dotted", color="orange") - lbc
    iam_dns - Edge(style="dotted", color="orange") - ext_dns
    iam_karp - Edge(style="dotted", color="orange") - karpenter
    iam_grafana - Edge(style="dotted", color="orange") - grafana
    iam_ebs - Edge(style="dotted", color="orange") - ebs_csi
