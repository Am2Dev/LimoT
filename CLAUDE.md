# CLAUDE.md - AI Assistant Guidelines for LimoT

This document provides essential context and guidelines for AI assistants working on the LimoT project.

## Project Overview

**LimoT** is a new open-source project licensed under Apache License 2.0.

### Current State

This repository is in its initial setup phase with minimal structure:
- `README.md` - Project description (to be expanded)
- `LICENSE` - Apache License 2.0
- `CLAUDE.md` - This file

## Repository Structure

```
LimoT/
├── README.md          # Project documentation
├── LICENSE            # Apache License 2.0
└── CLAUDE.md          # AI assistant guidelines
```

## Development Guidelines

### Git Workflow

1. **Branch Naming Convention**
   - Feature branches: `feature/<description>`
   - Bug fixes: `fix/<description>`
   - Documentation: `docs/<description>`
   - Claude AI branches: `claude/<description>-<session-id>`

2. **Commit Messages**
   - Use clear, descriptive commit messages
   - Start with a verb in present tense (Add, Fix, Update, Remove)
   - Keep the first line under 72 characters
   - Example: `Add user authentication module`

3. **Pull Requests**
   - Create PRs against the main branch
   - Include a clear description of changes
   - Reference any related issues

### Code Style

*(To be defined as the project develops)*

When code is added to this project, follow these general principles:
- Write clean, readable code with meaningful variable/function names
- Include appropriate error handling
- Add comments for complex logic only (code should be self-documenting)
- Follow the established patterns in the codebase

### Testing

*(To be defined as the project develops)*

When tests are added:
- Run all tests before committing
- Ensure new features have appropriate test coverage
- Do not commit code that breaks existing tests

## AI Assistant Instructions

### General Guidelines

1. **Read Before Editing** - Always read and understand existing files before making modifications
2. **Minimal Changes** - Make only the changes necessary to complete the task
3. **No Over-Engineering** - Keep solutions simple and focused on the current requirements
4. **Security First** - Avoid introducing vulnerabilities (OWASP Top 10)

### Task Approach

1. Understand the task requirements fully before starting
2. Explore the codebase to find relevant files and patterns
3. Follow existing code conventions and patterns
4. Test changes when applicable
5. Commit with clear, descriptive messages

### What to Avoid

- Adding features beyond what was requested
- Creating unnecessary abstractions or utilities
- Adding comments/documentation to unchanged code
- Introducing backwards-compatibility hacks
- Creating files unless absolutely necessary

## Build & Run Commands

*(To be added as the project develops)*

Example placeholder for future commands:
```bash
# Install dependencies
# npm install / pip install -r requirements.txt / etc.

# Run tests
# npm test / pytest / etc.

# Build project
# npm run build / make / etc.

# Start development server
# npm run dev / python main.py / etc.
```

## Dependencies

*(To be documented as dependencies are added)*

## Architecture

*(To be documented as the architecture is defined)*

## Contributing

This project follows the Apache License 2.0. Contributions are welcome following the development guidelines above.

---

*Last updated: 2025-12-27*
*This document should be updated as the project evolves.*
