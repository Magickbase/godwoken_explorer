name: Register a general contract
description: Required information to register a new general contract
title: '[General Contract] **Contract Name**'
labels: Contract Registration
assignees: Keith-CY

body:
  - type: input
    id: contract-name
    validations:
      required: true
    attributes:
      label: Contract Name
      description: Identifies the contract.
  
  - type: input
    id: contract-address
    validations:
      required: true
    attributes:
      label: Contract Address
      description: Contract address of the bridged token on the layer2.

  - type: dropdown
    id: code-file-format
    validations:
      required: true
    attributes:
      label: Code Format
      description: Select code file format
      options:
        - solidity single file (Default)
        - solidity multiple files
        - solidity standard json input
        - vyper

  - type: textarea
    id: constructor-arguments
    validations:
      required: false
    attributes:
      label: Constructor Arguments
      description: ABI-encoded constructor arguments.

  - type: input
    id: tx-hash
    validations:
      required: true
    attributes:
      label: Deployment Transaction Hash
      description: The hash of transaction which deployed the contract.

  - type: input
    id: compiler-version
    validations:
      required: true
    attributes:
      label: Compiler Version
      description: Compiler version used, e.g v0.8.11+commit.d7f03943

  - type: textarea
    id: contract-source-code
    validations:
      required: true
    attributes:
      label: Contract Source Code

  - type: textarea
    id: other-info
    validations:
      required: false
    attributes:
      label: Other Info
