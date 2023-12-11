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

  ## Voting.sol

  I started this journey by implementing the Voting.sol version of this smart contract. This contract handles basic requirements provided in the subject.
  I started by implementing the machine state and then the different operations and controls.

  👉  Most of the errors are not handled programmatically but left to the EVM for this version which means than rather implementing all controls I have left some errors being handled by the EVM rather than me. For example, I do not control the bounds of the propositions array when a user vote for a proposition with its ID.

  👉 Concerning winners: this smart contract does not handle equality between propositions and will select the first one with the highest score as the winner.
  
  ## VotingPlus.sol

  To work on a most advanced version of Voting.sol I have created VotingPlus.sol which takes the same basics but adds a few features to the voting system.

  Here is a list of added features:

  - __The smart contract handles equality__. In this version of the smart contract, several proposition can be ex aequo. Thus they will be listed when calling tailVotes function. 
    In order to solve this equality between propositions, the admin will have :
    - to call solveEqualityWithVote contract method. The solveEqualityWithVote method will reset the votes, remove all the propositions but those which are equal, and voters will be able to vote again to break the tie. 
    - to call solveEqualityWithTimestamp contract method: will choose as the winning proposition, the proposition which has the smallest timestamp (which is the oldest).
  - __All errors are now handled__
  - __Admin cannot be added as a voter__ anymore in order to not influence the vote and in order to not mix responsabilities between admin and voter roles.
  - __Voter can delegate its vote__ to an existing voter or to a new voter. He must use the delegateVote function to do so while the admin is registering voters. Once voters are registered and voters start registering proposition, vote delegation won't be possible anymore.
  - Threshold have been added between state machine steps (these figures can be changed using the appropriate modifiers)
      - 3 voters at least are required to validate RegisteringVoters state
      - 2 propositions at least are required to validate ProposalsRegistration state
      - 1 vote at least is required to end VotingSession state
  - __Useless states have been removed__
  - __Voters can only vote once__ unless another voter delegated them a voice
  - Propositions can be listed (id, description, voteCount)
  - Once the vote workflow is complete we can now start a new vote using restartVoteWorkflow.


  ## Source code

  👉 All source code has been documented or is otherwise self explanatory. Please look at it for further details.
  
