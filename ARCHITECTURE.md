# Tawf Governance System - Architecture Flow

This document explains the complete flow of the Tawf governance system based on the architecture diagram.

## System Components

### User Interfaces
1. **Community dApp** - For community members to participate in governance
2. **Vendor/Organizer Portal** - For campaign creators and service providers
3. **Sharia Council Interface** - For Islamic compliance review
4. **Tawf Labs Admin Console** - For system administration

## Flow Diagrams

### 1. Identity Registration Flow

```
User → Wallet → KYC Service
KYC Service → Tawf Labs Multisig (approval)
Tawf Labs Multisig → TawfDID Contract (issue DID)
TawfDID → IPFS (store metadata)
TawfDID → TawfReputation (initialize reputation)
```

**Implementation**:
- User registers through dApp with wallet connection
- KYC verification happens off-chain
- Multisig approves and triggers DID issuance
- Soulbound NFT minted to user's address
- Metadata stored on IPFS/Arweave
- Initial reputation score assigned

### 2. Vendor Registration Flow

```
Vendor → Vendor Portal → KYC Service
KYC Service → Tawf Labs Multisig
Multisig → VendorRegistry (verify vendor)
VendorRegistry → TawfDID (check DID exists)
```

**Implementation**:
- Vendor must have DID before registration
- Submits vendor details and undergoes KYC
- Admin reviews and verifies vendor
- Vendor can now create campaigns

### 3. Proposal Creation & Voting Flow

```
Community Member → CommunityDAO (create proposal)
CommunityDAO → ProposalRegistry (register)
ProposalRegistry → ZKShariaDAO (review)
Sharia Council → ZK Proof Generator (off-chain)
ZK Proof → ZKShariaDAO (submit review)
ZKShariaDAO → ProposalRegistry (approve/reject)
```

**Implementation**:
- User creates proposal (requires minimum reputation)
- Proposal enters voting period
- Community votes weighted by reputation
- Successful proposals sent to registry
- Sharia council reviews with ZK proofs for privacy
- Approved proposals batched for execution

### 4. Proposal Execution Flow

```
ProposalRegistry → Batch Creation
Batch → Tawf Labs Multisig (execution approval)
Multisig → Target Contracts (CampaignManager, WakafTreasury, etc.)
Execution → NFTReceiptIssuer (if applicable)
All Events → Indexer → Audit UI
```

**Implementation**:
- Registry batches approved proposals
- Multisig executes batches
- Actions affect protocol contracts
- Events indexed for transparency

### 5. Campaign Creation & Contribution Flow

```
Vendor → CampaignManager (create campaign)
CampaignManager → VendorRegistry (verify vendor)
Contributor → CampaignManager (contribute)
CampaignManager → NFTReceiptIssuer (issue receipt)
Receipt → IPFS (metadata)
Campaign Data → Indexer → Audit UI
```

**Implementation**:
- Verified vendors create campaigns with goals and duration
- Contributors send funds to campaign
- NFT receipt automatically issued
- Funds tracked transparently
- Vendor can withdraw after campaign completion

### 6. Treasury Allocation Flow

```
CommunityDAO → Proposal (treasury allocation)
Approved Proposal → WakafTreasury (create allocation)
WakafTreasury → Multisig (execution approval)
Multisig → WakafTreasury (execute allocation)
WakafTreasury → Recipient
Allocation → NFTReceiptIssuer (optional receipt)
```

**Implementation**:
- Community proposes treasury spending
- Goes through governance process
- Multisig executes approved allocations
- Transparent fund tracking

### 7. Emergency Controls Flow

```
Emergency Situation Detected
↓
Option 1: Protocol Admin → pause() → Target Contracts
Option 2: Sharia Council → emergencyVeto() → ProposalRegistry
Option 3: Multisig → Emergency Action → Any Contract
```

**Implementation**:
- Admin can pause critical contracts
- Sharia council can veto proposals
- Multisig can execute emergency actions
- All emergency actions logged

### 8. Reputation Update Flow

```
User Participation (voting, proposals, etc.)
↓
CommunityDAO/CampaignManager
↓
TawfReputation (increase/decrease)
↓
History Recorded
```

**Implementation**:
- Actions tracked automatically
- Reputation increases for positive participation
- Can be decreased for violations
- Slashing available for serious violations

## Data Flow

### On-Chain Data
- Identity records (DID tokens)
- Reputation scores
- Governance proposals and votes
- Campaign information
- Treasury allocations
- Transaction records

### Off-Chain Data (IPFS/Arweave)
- DID metadata (personal information)
- Proposal details and documents
- Campaign descriptions and media
- Receipt metadata
- Sharia review justifications

### Zero-Knowledge Proofs
- Sharia council voting (privacy-preserving)
- Compliance verification
- Private attestations

## Observability & Transparency

```
All Contracts → Events
Events → Indexer/Subgraph
Indexer → Audit & Transparency UI
```

**Tracked Metrics**:
- Total DIDs issued
- Active proposals
- Campaign statistics
- Treasury balance and allocations
- Reputation distribution
- Governance participation rates

## Security Mechanisms

1. **Role-Based Access Control**
   - Admin roles
   - Issuer roles
   - Executor roles
   - Council roles

2. **Multi-Signature Requirements**
   - Critical operations require M-of-N signatures
   - Configurable threshold

3. **Pausability**
   - Emergency pause for critical contracts
   - Admin-controlled

4. **Soulbound Tokens**
   - Non-transferable DIDs
   - Prevents identity trading

5. **Time Locks**
   - Voting delays and periods
   - Campaign durations

## Integration Points

### External Services
- **KYC/Verification**: Off-chain identity verification
- **IPFS/Arweave**: Decentralized storage
- **ZK Proof Generator**: Privacy-preserving proofs
- **Indexer/Subgraph**: Event indexing and queries

### Future Integrations
- Oracle services for external data
- Cross-chain bridges
- Additional storage solutions
- Advanced ZK systems

## Deployment Order

1. Identity Layer (TawfDID, TawfReputation)
2. Admin Layer (ProtocolAdmin, Multisig)
3. Protocol Layer (VendorRegistry, NFTReceiptIssuer, CampaignManager, WakafTreasury)
4. Governance Layer (CommunityDAO, ProposalRegistry, ZKShariaDAO)
5. Configure roles and permissions
6. Setup initial data

## Testing Strategy

1. Unit tests for each contract
2. Integration tests for flows
3. Governance simulation tests
4. Emergency scenario tests
5. Gas optimization tests
6. Security audits

---

For implementation details, see individual contract documentation in `src/` directories.
