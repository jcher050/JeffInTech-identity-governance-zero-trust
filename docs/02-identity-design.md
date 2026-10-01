# JeffInTech Identity Design

## Purpose

This document describes the identity model implemented for the fictional
JeffInTech Microsoft Entra ID environment.

The design uses HR attributes, Microsoft Entra ID, dynamic groups,
assigned security groups, and Microsoft Graph PowerShell automation
to create a scalable identity and access foundation.

---

## Phase 1 — Identity and Group Model

Implemented the initial JeffInTech identity authorization model using
Microsoft Entra ID and Microsoft Graph PowerShell.

### Implemented

- Created 25 fictional workforce identities.
- Populated HR-driven identity attributes.
- Configured manager relationships.
- Created four attribute-driven dynamic department security groups.
- Created dedicated pilot groups for SSPR and passwordless authentication.
- Created Conditional Access targeting groups.
- Created a contractor security group populated from HR identity attributes.
- Created a role-assignable Cloud Operators group for future PIM governance.
- Validated all expected groups after provisioning.
- Automated contractor membership based on `employeeType`.

---

## Identity Attribute Model

JeffInTech uses HR attributes as the authoritative source for identity
lifecycle and access decisions.

Key attributes include:

- `employeeId`
- `displayName`
- `userPrincipalName`
- `department`
- `jobTitle`
- `manager`
- `usageLocation`
- `employeeHireDate`
- `employeeLeaveDateTime`
- `employeeType`

Example:

```text
Victor Stone
Department: IT
Job Title: Cloud Engineer
Employee Type: Employee
Manager: Noah Harris












# JeffInTech Identity Design

## Purpose

This document describes the identity architecture implemented for the fictional
JeffInTech Microsoft Entra ID environment.

JeffInTech uses HR-driven identity attributes, Microsoft Entra ID, dynamic and
assigned security groups, manager relationships, and Microsoft Graph PowerShell
automation to establish a scalable identity foundation for lifecycle management,
access governance, Zero Trust, and privileged access.

> **Portfolio Disclaimer:** JeffInTech, its users, organizational structure,
> business data, and scenarios are fictional. This environment was created as a
> hands-on enterprise IAM engineering project.

---

## Environment Overview

**Organization:** JeffInTech  
**Primary identity platform:** Microsoft Entra ID  
**Primary domain:** `jeffintech.com`  
**Workforce identities:** 25 fictional users  
**Identity automation:** Microsoft Graph PowerShell  
**Identity source model:** HR-driven attributes  
**Access model:** Attribute-driven and governed group membership

The identity foundation is designed to support later implementation of:

- Joiner-Mover-Leaver automation
- Microsoft Entra Lifecycle Workflows
- Conditional Access
- MFA and passwordless authentication
- Identity Protection
- Privileged Identity Management
- Access Reviews
- Entitlement Management
- Hybrid identity
- Cross-tenant access
- Workload identities
- Identity monitoring and Microsoft Sentinel

---

# Phase 1 — Identity Foundation

Phase 1 establishes the authoritative identity model that the remaining IAM
architecture will depend on.

## Implemented

- Created 25 fictional workforce identities.
- Configured the verified `jeffintech.com` domain for user identities.
- Populated HR-driven user attributes.
- Configured organizational manager relationships.
- Created four dynamic department security groups.
- Created security groups for SSPR and passwordless pilot deployments.
- Created security groups for Conditional Access targeting.
- Created an assigned contractor security group.
- Automated contractor group membership using the `employeeType` attribute.
- Created a role-assignable Cloud Operators group for future PIM governance.
- Validated that all expected IAM groups were successfully provisioned.
- Implemented Microsoft Graph PowerShell automation for repeatable deployment.

---

# Identity Architecture

```text
                      JeffInTech HR Data
                              |
                              v
                    HR Identity Attributes
                              |
                              v
                Microsoft Graph PowerShell
                              |
                              v
                     Microsoft Entra ID
                              |
             +----------------+----------------+
             |                                 |
             v                                 v
      Workforce Identities              Security Groups
             |                                 |
      +------+------+                 +--------+--------+
      |             |                 |                 |
      v             v                 v                 v
 Employees     Contractors      Dynamic Groups    Assigned Groups
      |             |                 |                 |
      |       employeeType            |           CA / SSPR /
      |       = Contractor            |         Passwordless / PIM
      |             |                 |
      |             v                 v
      |      GRP-Contractors    Department Groups
      |                              |
      +------------------------------+
                     |
                     v
              Access Decisions
