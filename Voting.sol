// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);
    event VoteIsOver();

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

    uint private winningProposalId;
    WorkflowStatus private currentVoteState;    

    modifier votesTallied() {
        require(currentVoteState == WorkflowStatus.VotesTallied, "Votes need to be tallied in order to do that.");
        _;
    }

    modifier votesNotTallied() {
        require(currentVoteState != WorkflowStatus.VotesTallied, "Votes should not be tallied in order to do that.");
        _;
    }

    modifier registeringVoters() {
        require(currentVoteState == WorkflowStatus.RegisteringVoters, "Registering voters presently.");
        _;
    }

    modifier registeringProposals() {
        require(currentVoteState == WorkflowStatus.ProposalsRegistrationStarted, "Registering propositions presently.");
        _;
    }

    modifier votingProposals() {
        require(currentVoteState == WorkflowStatus.VotingSessionStarted, "Registering voters presently.");
        _;
    }



    constructor() Ownable(msg.sender) {
        currentVoteState = WorkflowStatus.RegisteringVoters;
    }


    function getVoteStep() external view returns (WorkflowStatus) {
        return currentVoteState;
    }

    function nextVoteStep() external onlyOwner votesNotTallied {
        WorkflowStatus previousState = currentVoteState;
        currentVoteState = WorkflowStatus(uint(currentVoteState) + 1);
        emit WorkflowStatusChange(previousState, currentVoteState);
    }
    
    function restartVote() external onlyOwner votesTallied {
        currentVoteState = WorkflowStatus.RegisteringVoters;
    }




    function getWinner() external votesTallied returns (address) {

    }
}