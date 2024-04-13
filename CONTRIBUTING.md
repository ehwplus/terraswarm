# Contributing to Terraswarm

Disclaimer: these guidelines are work in progress and might change any time.

Thank you for your interest in contributing to terraswarm! We value your effort and aim to make your contribution process as smooth as possible. Please follow these guidelines to help us maintain the quality and consistency of the codebase.

## Prerequisites

Before you begin, ensure that you have the necessary tools installed:

- **asdf**: We use `asdf` version manager to manage tool versions. Please install it from [asdf-vm.com](https://asdf-vm.com/).

## Getting Started

1. **Fork and clone the repository**:
   Start by forking the repository and then clone your fork to create a local copy.
   ```bash
   git clone https://github.com/<your-username>/terraswarm
   cd terraswarm
   ```

2. **Install dependencies**:
   Set up your development environment by pinning the executable versions using asdf. Ensure you are using the exact versions specified in the .tool-versions file.

   ```bash
   asdf install
   ```

3. **Activate the pre-commit hook**:
   We use pre-commit hooks to ensure that all Terraform code meets our standards for quality and consistency. Activate the pre-commit hook by running:

   ```bash
   pre-commit install
   ```

## Making Changes

 1. **Create a new branch**:
    Please create a new branch for each set of changes you wish to make.

    ```bash
    git checkout -b <new-branch-name>
    ```

 2. **Make your changes**:
    Implement your changes and commit them. Ensure your commit messages follow the conventional commits format, e.g., feat: add new feature, fix: correct a typo.

 3. **Test your changes**:
    Test the Terraform modules locally to ensure they work as expected. To do this:

    - Initialize the Terraform configuration:

      ```bash
      terraform init
      ```

    - Validate the configuration:

      ```bash
      terraform validate
      ```

    - Apply the configuration in a development environment:

      ```bash
      terraform plan
      terraform apply
      ```
      
    - Ensure there are no errors and all expected resources are correctly provisioned.

 4. **Update documentation**:
    If your changes require it, update the README.md or any other documentation that is affected by your changes.

## Submitting Your Changes

 1. **Push your changes**:
    Push your branch to your fork.

    ```bash
    git push origin <new-branch-name>
    ```

 2. **Create a pull request**:
    Go to the original repository you forked from, navigate to "Pull Requests", and click "New Pull Request". Use the branch you pushed as the source for the pull request.

 3. **Describe your changes**:
    In the pull request description, explain your changes, how they've been tested, and why they are necessary.

## Review Process

Our team will review your pull request and may suggest changes, improvements, or alternatives. Some things we look for include

- The changes fulfill a need or fix a problem.
- The changes maintain or improve the existing framework.
- The code follows our existing style and structure.

## Thank You!

We appreciate your effort in contributing to terraswarm! Your help improves the project and benefits all users.
