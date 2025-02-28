# VoteChain

A decentralized blockchain voting system built on Clarity smart contracts.

## Overview

VoteChain is a secure, transparent, and efficient voting system that leverages blockchain technology to ensure vote integrity and provide a trustless voting environment. The system allows for the creation of ballots, casting of votes, delegation of voting power, and transparent tallying of results.

## Features

- **Ballot Creation**: Create ballots with customizable choices and voting periods
- **Secure Voting**: Each eligible voter can cast exactly one vote per ballot
- **Influence System**: Voters can have different levels of voting influence
- **Proxy Voting**: Voters can delegate their voting power to a trusted proxy
- **Transparent Results**: All votes and tallies are publicly verifiable on the blockchain
- **Time-Based Voting**: Voting periods are managed through an epoch system
- **Governance Controls**: Administrative functions to manage the voting system

## Smart Contract Structure

The VoteChain system consists of the following key components:

### Data Structures

- **Ballots**: Stores ballot information including title, choices, expiration, and vote tally
- **Ballots-Cast**: Records individual votes with the voter's choice and influence
- **VoterInfluence**: Tracks each voter's voting influence
- **Proxies**: Maps voting power delegation relationships

### Core Functions

- `create-ballot`: Create a new ballot with specified choices and duration
- `submit-vote`: Cast a vote on an active ballot
- `assign-proxy`: Delegate voting power to another voter
- `close-ballot`: End voting on a specific ballot
- `advance-epoch`: Increment the system's time counter

### Read-Only Functions

- `get-ballot-tally`: View the total votes cast on a ballot
- `get-voter-influence-level`: Check a voter's voting influence
- `get-ballot-status`: Determine if a ballot is still active
- `get-current-epoch`: Get the current system time

## Usage

### Prerequisites

- A Stacks blockchain wallet
- Sufficient tokens for transaction fees

### Creating a Ballot

```clarity
(create-ballot "Community Garden Proposal" (list "Approve" "Reject" "Abstain") u100)
```

### Casting a Vote

```clarity
(submit-vote u1 "Approve")
```

### Delegating Voting Power

```clarity
(assign-proxy 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## Security

VoteChain implements several security measures:

- Prevention of double voting
- Validation of all user inputs
- Protection against delegation cycles
- Time-locked voting periods
- Access control for administrative functions

## Development

### Building Locally

1. Clone the repository
2. Install Clarity development tools
3. Run tests with `clarinet test`

### Testing

The contract includes a comprehensive test suite covering all core functionality.
