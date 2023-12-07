// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    uint winningProposalId;

    constructor() Ownable(msg.sender) {}

    function getWinner() external returns (address) {

    }
}