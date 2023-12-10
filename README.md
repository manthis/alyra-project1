# ⚡️ Alyra : Project 1 - Système de Vote

Un smart contract de vote peut être simple ou complexe, selon les exigences des élections que vous souhaitez soutenir. Le vote peut porter sur un petit nombre de propositions (ou de candidats) présélectionnées, ou sur un nombre potentiellement important de propositions suggérées de manière dynamique par les électeurs eux-mêmes.

Dans ce cadres, vous allez écrire un smart contract de vote pour une petite organisation. Les électeurs, que l'organisation connaît tous, sont inscrits sur une liste blanche (whitelist) grâce à leur adresse Ethereum, peuvent soumettre de nouvelles propositions lors d'une session d'enregistrement des propositions, et peuvent voter sur les propositions lors de la session de vote.

- Le vote n'est pas secret pour les utilisateurs ajoutés à la Whitelist
- Chaque électeur peut voir les votes des autres
- Le gagnant est déterminé à la majorité simple
- La proposition qui obtient le plus de voix l'emporte.
- N'oubliez pas que votre code doit inspirer la confiance et faire en sorte de respecter les ordres déterminés!

## 👉 Le processus de vote

Voici le déroulement de l'ensemble du processus de vote :

- L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum.
- L'administrateur du vote commence la session d'enregistrement de la proposition.
- Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.
- L'administrateur de vote met fin à la session d'enregistrement des propositions.
- L'administrateur du vote commence la session de vote.
- Les électeurs inscrits votent pour leur proposition préférée.
- L'administrateur du vote met fin à la session de vote.
- L'administrateur du vote comptabilise les votes.
- Tout le monde peut vérifier les derniers détails de la proposition gagnante.

## 👉 Les recommandations et exigences

- Votre smart contract doit s’appeler “Voting”.
- Votre smart contract doit utiliser la dernière version du compilateur.
- L’administrateur est celui qui va déployer le smart contract.
- Votre smart contract doit définir les structures de données suivantes :
  ```js
    struct Voter {
      bool isRegistered;
      bool hasVoted;
      uint votedProposalId;
    }
    struct Proposal {
      string description;
      uint voteCount;
    }
  ```
- Votre smart contract doit définir une énumération qui gère les différents états d’un vote
  ```js
    enum WorkflowStatus {
      RegisteringVoters,
      ProposalsRegistrationStarted,
      ProposalsRegistrationEnded,
      VotingSessionStarted,
      VotingSessionEnded,
      VotesTallied
    }
  ```
- Votre smart contract doit définir un uint *winningProposalId* qui représente l’id du gagnant ou une fonction *getWinner* qui retourne le gagnant.
- Votre smart contract doit importer le smart contract la librairie “Ownable” d’OpenZepplin.
- Votre smart contract doit définir les événements suivants :
  ```js
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);
  ```
  ___ 

  # ⚡️ Talking about this project

  Here is how I have proceed to build the voting contract:
  1. I started with the state machine which is the most complex part of this contract. The idea was to keep it as simple as possible.
  2. I then implemented the different methods in order to fulfill the contract specifications provided above.

  
  👉 Most of the errors are not handled programmatically but left to the EVM. Ex: the state machine doesn't control its bounds. If it is required to move to
  a step which does not exist (an unknown index of the table), an error occurs and is handled by the EVM.


  👉 Concerning winners: this smart contract does not handle equality between propositions and will select the first one with the highest score as the winner.


  ## Identified issues with a voting contract

  Below is a list of all the corner cases of a vote we would need to handle to make this contract perfect:
  
  - Handle equality: two propositions cannot be equal, if we find an equality we must vote again but for the equal propositions only
  - Handle errors: vote for an non existing proposition, move to a state of the state machine which does not exist, etc.
  - Admin should not be able to be a voter
  - We should not be able to pass to next machine state if we don't have voters, if we don't have proposals or if we don't have votes
  - We should remove states which are useless from the state machine
  - We should only be able to vote once
  - A voter should be able to delegate its vote
  - A voter should be able to cancel or modify its vote
  - A voter should be able to emit a blank vote
  - People should be able to count for themselves and see if the result of the vote is true
  - A voter should not be able to vote for a proposition which does not exist
  - Once the vote is complete we should be able to reinstanciate a new voting session

  
  👉 We have implemented all theses additional feature in the VotingPlus.sol file. Please look at it.