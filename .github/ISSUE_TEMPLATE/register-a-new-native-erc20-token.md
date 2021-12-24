name: Register a new native ERC20 token
description: Required information to register a new native erc20 token
title: '[Native ERC20 Token] **Token Name**'
labels: Token Registration
assignees: Keith-CY

body:
  
  - type: input
    id: token-name
    validations:
      required: true
    attributes:
      label: Token Name
      description: Identifies the asset represented by this token.
      placeholder: e.g. Nervos CKB

  - type: textarea
    id: description
    validations:
      required: true
    attributes:
      label: Description
      description: Describe the asset represented by this token.

  - type: input
    id: max-supply
    validations:
      required: false
    attributes:
      label: Max Supply
      description: Specify the maximum amount of the asset identified by this token.
      placeholder: e.g. 21000000 BTC

  - type: input
    id: website
    validations:
      required: false
    attributes:
      label: Website
      description: The website of the project for more information.

  - type: input
    id: logo
    validation:
      required: true
    attributes:
      label: Logo URI
      description: The logo of the project to easily recongize.

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
