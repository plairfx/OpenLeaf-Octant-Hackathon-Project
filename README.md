### OpenLeaf
This project has been built for the [Octant Hackathon](https://octant.devfolio.co/overview).

OpenLeaf: Your Gateway to Protocol Transparency

Live Demo: openleaf-fe.vercel.app/

### Overview

**What is OpenLeaf?**

OpenLeaf is a protocol that allows users to track the activity of their favourite protocol. Many questions arise from users: where and how is the protocol spending their treasury funds? As a user and investor, the one thing that matters the most is **Transparency**.

By adding the feature for protocols to track their wallets/treasury multisig, this allows them to showcase to their users how they are spending the money. By adding details on their transactions, they can know exactly if they are spending maliciously or not.

But why does this even matter? You can say that protocol spending should be private, but we all know that most protocols don't really showcase the numbers they are spending, and this is mostly caused by one reason: critics from people who don't know.

How can we safely showcase the spending of protocols while still keeping the transparency alive?

**Community Initiative**

We all want the community to help a protocol forward, but is there even a good way at the moment that supports that? How can protocols be happy having feedback?

We offer protocols to publish their tasks on the blockchain, and if they find someone that is suited for the job, they pay them. If not, no need to pay.

**Earn Yield While Simultaneously Funding Tasks**

We allow protocols to earn yield through their deposits into the vault. Right now we support Spark Strategy (USDC savings vault), which makes sure they earn a fair rate (4.25% at the moment of typing) while funding their tasks.

### Contracts

The protocol consists of these main contracts:
- **Registry.sol**: Allows protocols to register their project, with the option of depositing yield.
- **TaskManager.sol**: Allows protocol admins to create, delete and accept tasks from/for their users.
- **SubmissionManager.sol**: Allows users to submit submissions in a task from a protocol they are interested in.
- **VaultFactory.sol**: Powers Registry.sol to create a vault for a user.
- **SparkStrategy.sol**: Manages the interactions with Spark USDC vault.

### Frontend

You can view the frontend at: https://github.com/ivcained/Open-Leaf-Frontend
