# ⚡AeroStream | Event-Driven Serverless Data Pipeline

An enterprise-grade, fully decoupled, asynchronous data ingestion and processing pipeline built for ultra-high velocity traffic. **ZeroScale** acts as a bulletproof structural shock absorber, swallowing massive bursts of real-time event streams (webhooks, user clicks, transactional logs) without dropping a single packet or breaking the bank.

---

## 🚀 Architecture Overview

Unlike traditional monolithic applications, where a spike in web traffic can overload your backend or choke your database, **ZeroScale** uses an **asynchronous buffer-first architecture**.

```
  [ Client Traffic ] 
          │  (High-Velocity JSON Streams)
          ▼
┌───────────────────┐
│  API Gateway v2   │ ────► Instantly acknowledges client with 202 Accepted
└─────────┬─────────┘
          │ (Direct Service Integration / No Compute Overhead)
          ▼
┌───────────────────┐
│ Amazon SQS Buffer │ ────► Throttles & absorbs sudden traffic spikes
└─────────┬─────────┘
          │
          ├─── (Healthy Batches) ───► ┌───────────────────────┐
          │                           │   AWS Lambda Engine   │ ───► [ Cleaned Data ]
          │                           └───────────┬───────────┘
          │                                       │
          │                                       ▼
          │                           ┌───────────────────────┐
          │                           │   Amazon CloudWatch   │
          │                           └───────────────────────┘
          │
          └─── (Poison Pill/Fails) ─► ┌───────────────────────┐
                                      │  Dead Letter Queue    │ ───► [ Isolated for Debugging ]
                                      └───────────────────────┘

```

---

## ✨ Features & Production Mechanics

* **⚡ Sub-Millisecond Ingestion:** Uses a direct AWS proxy integration between API Gateway and Amazon SQS. Incoming data skips the compute layer entirely upon arrival, cutting out execution latency.
* **🛡️ Asynchronous Blast Radius Isolation:** A robust **Dead Letter Queue (DLQ)** safety net isolates corrupted or malicious payloads ("poison pills") automatically after 3 retry failures, protecting the rest of the operational pipeline.
* **💰 True Zero-Cost Idle State:** Built 100% on serverless primitives. When there is no incoming traffic, your compute footprints scale to absolute zero—costing exactly **$0.00** to maintain.
* **🏗️ 100% Declarative Infrastructure:** The entire system—including complex IAM roles, security permissions, message queues, and endpoints—is provisioned deterministically using **Terraform (Infrastructure as Code)**.

---

## 🛠️ Tech Stack & Production Tooling

| Component | Technology | Purpose |
| --- | --- | --- |
| **IaC** | `Terraform (HCL)` | Infinite environment replicability and automated provisioning |
| **Gateway** | `Amazon API Gateway v2` | Low-latency HTTP entry point for JSON data payloads |
| **Broker** | `Amazon SQS` | Asynchronous message buffering, throttling, and long-polling |
| **Compute** | `AWS Lambda` | Serverless Python engine for data transformation & business logic |
| **Telemetry** | `Amazon CloudWatch` | Live metric auditing, state tracking, and error monitoring |
| **Sim Engine** | `Python 3.11` | Local mock script simulating real-world concurrent platform load |

---

## 📂 Repository Blueprint

```text
zeroscale-pipeline/
├── terraform/                  # 🏗️ Infrastructure-as-Code Configuration
│   ├── main.tf                 # Core AWS resource definitions (SQS, Lambda, API Gateway)
│   ├── variables.tf            # Environment and region declarations
│   ├── outputs.tf              # Exposes deployment metrics (e.g., Target Ingestion URL)
│   └── lambda_function.py      # 🐍 Core data processing & error-routing engine
├── scripts/                    # 🧪 System Validation & Stress Testing
│   └── ingest_mock_data.py    # Python simulator blasting multi-threaded events
├── .gitignore                  # Prevents state caching leakage
└── README.md                   # This master documentation

```

---

## 🏎️ Deployment & Execution Blueprint

### 1️⃣ Cloud Infrastructure Setup

Spin up your entire, production-grade AWS cloud landscape with three terminal commands:

```bash
# Navigate to the infrastructure folder
cd terraform/

# Initialize Terraform modules and cloud providers
terraform init

# Review the execution plan before modifying resources
terraform plan

# Deploy the entire ecosystem live to AWS
terraform apply --auto-approve

```

> 💡 **Interviewer Note:** Upon completion, Terraform will output a secure, live URL string to your console. Copy this value (e.g., `[https://xyz123.execute-api.us-east-1.amazonaws.com/collect](https://xyz123.execute-api.us-east-1.amazonaws.com/collect)`).

### 2️⃣ Running Live System Validation

Simulate real-world client traffic hitting your active platform by updating the endpoint variable inside `scripts/ingest_mock_data.py` and running:

```bash
# Install dependencies
pip install requests

# Execute the test framework
python scripts/ingest_mock_data.py

```

### 3️⃣ Verifying Resiliency & Observability

Open up your AWS Console to observe production-level fault tolerance in action:

1. **CloudWatch Logs:** Watch the Lambda process healthy event records in optimized parallel batches, applying data cleaning transformations automatically.
2. **SQS Metrics:** Watch your test script’s intentional "malformed payload" try to execute, retry 3 times, fail safely, and get pushed to the **Dead Letter Queue (DLQ)** without bringing down your running application script.

### 4️⃣ Zero-Cost Teardown

To prevent ongoing cloud provider billing when this project is not active, tear down the environment instantly:

```bash
terraform destroy --auto-approve

```

---

## 🧠 Architectural Insights 

### Why this design beats standard architectures:

* **Decoupled Component Lifecycles:** If the backend logic needs an update or crashes completely, **the API Gateway never goes down.** Data continues to stream safely into the SQS queues, storing inputs until the processing layer comes back online.
* **Backpressure Remediation:** Standard REST setups buckle when real-time loops spike. SQS natively handles backpressure, feeding messages to the Lambda computing instances only at a rate your app can safely ingest.
* **Enterprise-Grade Error Budgets:** Implementing an active DLQ structure shows a production-first mindset. Instead of simply dropping messages on failure or letting errors loop infinitely, bad logs are systematically isolated for post-mortem auditing.
* 
---

## 🤝 Feel Free to Contribute!

Contributions make the open-source community an amazing place to learn, inspire, and create. Whether you want to optimize the Lambda parsing performance, switch the infrastructure over to an AWS Kinesis data stream, or enhance the dashboard visibility—your input is welcome!

Here is how you can jump in:

1. **Fork** the Project.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a **Pull Request**.

---

### Made with ❤️ by Pranav Rajput

Thank you to all the contributors, builders, and innovators who explore, test, and elevate this architecture. Let's build cooler, faster, and infinitely scalable systems together! ⭐





