---
description: Workflow for App Routing
---

# App Routing Workflow

To maintain a consistent and error-free navigation experience, follow these guidelines:

## 1. Route Definitions (main.dart)
- Prefer static paths without mandatory parameters for top-level navigation (e.g., `/home` instead of `/home/:role`).
- Use `ShellRoute` for sharing common UI components like headers and bottom navigation.
- If a parameter is needed, ensure all navigation calls to that route include it, or make it optional.

## 2. Navigation in UI
- Use `context.pop()` for "Back" buttons to return to the previous screen in the stack.
- Use `context.go('/path')` for top-level navigation (e.g., from bottom bar).
- Use `context.push('/path')` if you want to push a screen onto the stack and later `pop()` back.

## 3. Handling Auth State
- Navigation should be reactive to `appSessionControllerProvider` or similar auth providers.
- Avoid manual navigation redirection in individual screens; use the `routerConfig`'s redirect or a top-level listener in `MaterialApp`.

## 4. Troubleshooting
- If a screen shows a "route not found" error, check if the path being called exactly matches the definition in `main.dart` (including parameters).
- Ensure `extra` objects passed between routes are non-null or handled safely.
