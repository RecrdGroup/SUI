## Anonymous User uses app after onboarding

```mermaid
flowchart TD
  A(User uses RECRD App) --> B[Anonymous User Actions]
	B --> C[Watches Video Masters]
	C --> CA[RECRD keeps track of daily user watch time]
	CA --> D[RECRD updates Profile with watch time]:::onChainAction
	D --> E(User uses RECRD App)

classDef onChainAction fill:#8470FF
classDef suiInfra fill:#C4A484
```