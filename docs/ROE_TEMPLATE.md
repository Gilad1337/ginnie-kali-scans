# Rules of Engagement (ROE) Template

## Authorization
- authorized: true/false
- owner: <organization>

## In Scope
- domains: [list]
- cidr: [list]
- gcp_projects: [list]

## Maintenance Windows
- start: <ISO8601>
- end: <ISO8601>

## Contacts
- [list of emails]

## Restrictions
- No destructive tests
- No credential attacks
- No data exfiltration
- Only scan assets listed above

---
*Fill out and place in /AUTHORIZATION/authorization.json before running any scans.*
