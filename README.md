# Microservices and Infrastructure
## 1. Choose the infrastructure platform to use
Selecting Infrastructure Platform, depends on multiple factors and use cases.

Here are few common options for Infrastructure platforms:
- Self hosted
- Public Cloud Provider
- Hybrid

**Automated deployments:**
Automated deployments of Infrastructure and Application is achievable on both Private(on-prem) and Public cloud setup.

**Autoscaling:**
Autoscaling on on-prem setup depends on existing infrastructure and could become a bottleneck if there are less number of VMs to serve the load.
In Public Cloud, Autoscaling is one of the most useful feature which helps in allotting more compute resources based on the load, which is significantly higher compared to small/moderate on-prem data centers.
For short term load serving, Public cloud’s Autoscaling could be more cost effective (pay as you go) compared to on-prem setup where we need Capacity planning and maintain additional Infrastructure provisioned before the load burst.

**High Availability/Fault Tolerance:**
We can achieve High Availability in both On-prem and Public Cloud, but it's much easier and cost-effective to do in Public cloud where we can create subnets in another Availability Zone and have VMs serving traffic behind the load balancer.

But Fault Tolerant setup for mission critical applications requires redundant Infrastructure which should be in another region, so that even regional outages do not impact the service availability.

We can achieve Fault Tolerance in Public cloud easily since there are multiple Regions available, but it would definitely cost more to continuously run redundant setup.
For on-prem we need to have an additional data center in another location/zone/region with redundant infrastructure.

Setup for Fault Toleration costs more in both on-prem and Public Cloud, but Public cloud could still be cheaper if we keep redundant setup with minimum number of VMs and Auto-scale when the load increases in the event of outage.


**My Selection of Infrastructure Platform:**

If we already have Data centers available with enough capacity, I’ll select the on-prem Infrastructure Platform but if we have limited capacity and expect higher load then I’ll select the Public Cloud Platform.

Also,if there are concerns related to Compliance, I’ll definitely use on-prem Infrastructure Platform to have more control

For on-prem setup, we can use Platform as a Service(PaaS) such as Openshift, Rancher, Cloud Foundry, etc.

**Since I do not have on-prem setup, I'll use AWS Cloud Provider as Infrastructure Platform**

## 2. Orchestrator of choice:
Orchestration of Frontend/Backend microservices and Database tier can be segregated as below:

**Frontend and Backend Microservices:**
- Kubernetes **(Preferred Option)**

     _Reason to select: Vendor Agnostic, flexibility, customization and control_


- Container as a Service (CaaS) - such as ECS, Cloud Foundry

    _Reason to select: Simplified deployment and zero to minimum maintenance_

**Database:**

- **Kubernetes** Cluster running **Postgres Operator** - https://cloudnative-pg.io/ **(Preferred Option)**

- Managed Database as a Service - DBaaS 

_Reason to select: If we are using CaaS, managed Database will be make more sense due to less maintenance efforts_


_Kubernetes can be used for both application container/pods orchestration as well as running databases using **Postgres Operator**, this setup is also **vendor agnostic** compared to another option of using Cloud Providers’s CaaS and managed DBaaS._

**My selection:
Kubernetes**
