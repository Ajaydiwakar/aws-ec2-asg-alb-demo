# AWS EC2 + Auto Scaling + Application Load Balancer Demo

A classroom demonstration project showing how to deploy a Python Flask application on Amazon EC2 and integrate it with:

- Amazon EC2
- Private Subnets
- Bastion Host
- Application Load Balancer
- Target Groups
- Auto Scaling Groups
- EC2 User Data
- systemd
- Python virtual environments
- Health checks
- Path-based routing
- Host-based routing
- CPU-based Auto Scaling
- EC2 instance metadata

---

# Architecture

```text
                         Internet
                            |
                            |
                            v
                +------------------------+
                |   Application Load     |
                |       Balancer         |
                |                        |
                | HTTPS :443             |
                +-----------+------------+
                            |
                            |
                       Target Group
                         HTTP :6100
                            |
                 +----------+----------+
                 |                     |
                 v                     v
          +-------------+       +-------------+
          | EC2 App A   |       | EC2 App B   |
          | Private     |       | Private     |
          | Subnet      |       | Subnet      |
          | :6100       |       | :6100       |
          +------+------+       +------+------+
                 |                     |
                 +----------+----------+
                            |
                            v
                    Auto Scaling Group


Administration:

       Administrator
             |
             | SSH :22
             v
       +-------------+
       | Bastion Host|
       | Public Subnet
       +------+------+
              |
              | SSH :22
              v
       Private EC2 instances