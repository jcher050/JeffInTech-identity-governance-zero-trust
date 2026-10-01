# JeffInTech Entra Identity Modernization — Business Requirements

> **Portfolio Disclaimer:** JeffInTech, Orion, all users, business data, and scenarios in this repository are fictional. This project is a hands-on enterprise IAM simulation created to demonstrate Microsoft Entra ID engineering, security, automation, governance, and Zero Trust capabilities.

## Executive Summary

JeffInTech is a simulated organization with approximately 25 users, contractors, remote employees, Microsoft 365, Azure resources, SaaS applications, and a legacy on-premises Active Directory environment.

Following the acquisition of Orion, JeffInTech must modernize identity and access management across two organizations while reducing manual administration, excessive privilege, stale access, authentication risk, and limited audit visibility.

This project designs and implements an enterprise Microsoft Entra identity architecture covering:

* Joiner-Mover-Leaver (JML) automation
* Microsoft Entra ID and hybrid identity
* Microsoft Graph and PowerShell automation
* Conditional Access, MFA, and Zero Trust
* Identity Protection and risk-based access
* Privileged Identity Management (PIM)
* Entitlement Management and Access Packages
* Access Reviews and guest lifecycle governance
* Cross-tenant access for Orion Parts
* Enterprise applications and workload identities
* Managed identities and secret reduction
* Identity monitoring using Entra logs, Log Analytics, KQL, and Microsoft Sentinel

---
## Phase 1 — Identity Foundation ✅

Built the initial **JeffInTech identity foundation** using Microsoft Entra ID and Microsoft Graph PowerShell, establishing an HR-driven identity model for lifecycle automation, governance, and Zero Trust access.

### Implemented

- Provisioned **25 fictional workforce identities** using Microsoft Graph PowerShell
- Standardized HR identity attributes including:
  - `employeeId`
  - `department`
  - `jobTitle`
  - `employeeType`
  - `employeeHireDate`
  - `employeeLeaveDateTime`
  - `usageLocation`
- Configured manager relationships to establish an organizational hierarchy
- Created dynamic department security groups for:
  - Finance
  - Sales
  - Human Resources
  - IT
- Automated contractor classification and membership in `GRP-Contractors`
- Created dedicated **SSPR** and **Passwordless Authentication** pilot groups
- Created security groups for future **Conditional Access** policy targeting
- Created `GRP-PIM-CloudOperators` as a **role-assignable security group** for future Privileged Identity Management (PIM)
- Added validation logic to confirm all required IAM groups were successfully provisioned

### Identity Model

```text
HR Identity Data
       │
       ▼
Microsoft Graph PowerShell
       │
       ├── Users
       ├── HR Attributes
       ├── Manager Relationships
       ├── Dynamic Department Groups
       ├── Contractor Membership
       └── IAM / Security Groups
                │
                ▼
        Microsoft Entra ID
          jeffintech.com
