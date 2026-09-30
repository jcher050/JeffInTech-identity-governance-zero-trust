# JeffInTech Entra Identity Modernization — Business Requirements

> **Portfolio Disclaimer:**
> This project is a hands-on enterprise IAM simulation created to demonstrate Microsoft Entra ID engineering, security, automation, governance, and Zero Trust capabilities.

## Executive Summary

JeffInTech is a simulated  organization with approximately 25 users, contractors, remote employees, Microsoft 365, Azure resources, SaaS applications, and a legacy on-premises Active Directory environment.

Following the acquisition of Orion Parts, JeffInTech must modernize identity and access management across two organizations while reducing manual administration, excessive privilege, stale access, authentication risk, and limited audit visibility.



## Business Problem

JeffInTech currently relies heavily on manual identity administration.

HR emails IT when employees are hired, transferred, or terminated. Administrators manually create accounts, assign licenses and groups, manage contractors, and remove access.

The Orion acquisition introduces additional complexity because identities, applications, and access must now be governed across two Microsoft Entra tenants.

The organization also lacks a consistent way to answer:

> **Who has access?**
> **Why do they have access?**
> **Who approved it?**
> **Is the access still necessary?**
> **What did the identity do?**

---

## Current-State Risks and Target-State Solutions

| Business / Security Problem                 | IAM Engineering Solution                                |
| ------------------------------------------- | ------------------------------------------------------- |
| HR manually emails IT for new hires         | HR/API-driven identity lifecycle automation             |
| Accounts and groups are manually created    | Microsoft Graph + PowerShell automation                 |
| Transfers retain previous permissions       | Automated Mover workflow and access cleanup             |
| Terminated users may retain access          | Disable account, revoke sessions, and remove access     |
| Contractors remain indefinitely             | Access Packages, expiration, and Access Reviews         |
| Licenses are manually assigned              | Group-based licensing                                   |
| Administrators have permanent privilege     | PIM and just-in-time privileged access                  |
| Privileged access lacks strong oversight    | Approval, MFA, time limits, and PIM auditing            |
| Guest access is rarely reviewed             | Guest lifecycle governance and recurring Access Reviews |
| MFA enforcement is inconsistent             | Conditional Access and authentication policies          |
| Risky sign-ins are difficult to respond to  | Microsoft Entra ID Protection                           |
| Legacy authentication increases risk        | Conditional Access authentication controls              |
| On-premises identities require cloud access | Microsoft Entra Cloud Sync / hybrid identity            |
| Apex and Orion operate separate tenants     | Cross-tenant access and B2B collaboration               |
| Applications depend on stored secrets       | Managed identities and workload identities              |
| Application permissions lack governance     | App registrations, API permissions, consent governance  |
| Remote access relies on network trust       | Zero Trust and identity-aware access controls           |
| Identity logs are not centrally analyzed    | Entra logs, Log Analytics, KQL, and Sentinel            |
| Management lacks access visibility          | Identity Governance, audit logs, and access reporting   |

---

## Target-State Architecture

The target environment follows four principles:

**Automate identity lifecycle**
HR-driven identity changes automatically trigger provisioning, modification, and deprovisioning.

**Verify access continuously**
Conditional Access, MFA, device and sign-in risk, session controls, and Zero Trust principles determine whether access should be granted.

**Use least privilege**
Administrative permissions are eligible and activated only when required through PIM instead of remaining permanently assigned.

**Govern access throughout its lifecycle**
Employees, contractors, guests, privileged users, and workload identities receive only justified, approved, reviewable, and time-bound access.

---

## IAM Capabilities Demonstrated

| Engineering Area                    | Capabilities                                                                                                 |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Identity Management**             | Users, groups, licenses, attributes, external identities, hybrid identity, Cloud Sync, cross-tenant access   |
| **Authentication & Access**         | MFA, Conditional Access, authentication methods, session controls, Identity Protection, Zero Trust           |
| **Workload & Application Identity** | Enterprise apps, app registrations, service principals, managed identities, API permissions, Microsoft Graph |
| **Identity Governance**             | JML, Lifecycle Workflows, Entitlement Management, Access Packages, Access Reviews, PIM, privileged access    |
| **Automation**                      | PowerShell, Microsoft Graph API, bulk operations, identity lifecycle scripting                               |
| **Monitoring & Audit**              | Sign-in logs, audit logs, provisioning logs, Log Analytics, KQL, Sentinel, access reporting                  |

---

## Success Criteria

The modernization is considered successful when Apex can demonstrate that:

* New hires receive required identity, group, license, and application access through a repeatable onboarding process.
* Department transfers remove obsolete access before or while granting new access.
* Terminated users are disabled, active sessions are revoked, and unnecessary access is removed.
* Contractors and guests have approved, reviewable, and time-bound access.
* Administrative privileges are normally inactive and activated through PIM when required.
* Conditional Access consistently enforces authentication and Zero Trust requirements.
* Applications use appropriately governed workload identities instead of unnecessary long-lived secrets.
* Apex and Orion can collaborate securely across tenant boundaries.
* Identity events are centrally logged, queried, investigated, and reported.
* Access records provide evidence of **who received access, why it was granted, who approved it, whether it remains necessary, and what activity occurred.**

---

## Project Outcome

The final solution transforms JeffInTech from a primarily **manual, trust-based IAM environment** into an **automated, governed, least-privilege, Zero Trust identity platform** built around Microsoft Entra.

The repository documents the architecture, configuration decisions, automation, security policies, testing, troubleshooting, monitoring queries, and implementation evidence required to operate and support the environment.
