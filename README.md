# raptoreumnode-docker — HA Raptoreum Smartnode for Flux

A 2-instance, self-healing Raptoreum smartnode image for the Flux marketplace.
Reuses the shared Flux HA masternode template verbatim; only `coin.env` differs.
All values verified against Raptor3um/raptoreum source.

## Why it works like the Dash MN
Raptoreum is a DIP3 Dash fork: `protx info` / `protx update_service` are the same
RPCs, so the leader-election + failover controller (`mn-autoheal.sh`) is identical.
Coin-specific values live in **`coin.env`** (source: port chainparams.cpp:243,
bls init.cpp:877, datadir util/system.cpp:733):

| | Dash | Raptoreum |
|---|---|---|
| daemon / cli | dashd / dash-cli | raptoreumd / raptoreum-cli |
| port | 9999 | **10226** |
| BLS conf key | masternodeblsprivkey | **smartnodeblsprivkey** |
| datadir | /root/.dashcore | /raptoreum/.raptoreumcore |
| collateral | 1000 DASH | **1,800,000 RTM** |

## Behaviour
- **v8, `instances: 2`, `staticip: true`** — two warm nodes on stable-IP FluxNodes,
  each with its own chain. Only the leader holds the registration; a survivor takes
  over via ProUpServTx on leader death (failover in minutes). No forced failback.
- `node_initialize.sh` — writes `externalip=<FLUX_NODE_HOST_IP>:10226` every boot.
- `mn-autoheal.sh` — leader election + self-heal + PoSe-ban revive (unit-tested).
- `check-health.sh` — non-fatal daemon/SN status report.

## User inputs (marketplace)
- `KEY` — operator BLS private key
- `PROTXHASH` — smartnode registration hash (proTxHash)
- Plus a small RTM fee balance sent once to the fee-source address printed on startup.

## Deploy order
1. Build & push `runonflux/raptoreumnode:latest` from this repo.
2. Add `rtmsn.marketplace.json` as the `RaptoreumSN` entry in `fluxstats/config/marketplaceApps.json`.
3. User registers the smartnode (1.8M RTM collateral) from their wallet, provides
   `KEY` + `PROTXHASH`, funds the fee address once.

## Not yet validated
Built + unit-tested (stubbed cli). A real `docker build` and a testnet
`protx update_service` dry-run are still pending. `protx info` `.state.PoSeBanHeight`
is confirmed present in source (deterministicmns.cpp:58).

## Binary pin — IMPORTANT
The Dockerfile pins **`RTM_VERSION=2.0.3.01-mainnet`** and the `raptoreum-ubuntu22-*`
asset (note the trailing `-` before `.tar.gz`). Do NOT switch to "latest": the newest
tag (`2.0.4.01`) ships **testnet-only** binaries.
