# CareClinic Mobile App (Flutter)

Flutter client for the CareClinic Mobile System.

## Setup

1. Install dependencies:

```bash
flutter pub get
```

2. Confirm API base URL in `lib/services/api_service.dart` points to your PC LAN IP:

```dart
static const String baseUrl = 'http://192.168.1.45:8000/api';
```

3. Ensure phone and PC are on the same Wi-Fi.

4. Run the app:

```bash
flutter run
```

## Architecture Overview

- `main.dart`: bottom-tab shell
	- Dashboard
	- Patients
	- Appointments
	- Consultations
	- Claims
- `services/api_service.dart`: centralized HTTP layer
- `screens/**`: feature-specific UI and workflows

Notable flows implemented:

- Appointment create/edit with conflict warning popup
- Time-based appointment actions (`Edit` vs `End Appointment` / `No Show`)
- Consultation capture with vitals + notes
- Patient archive/restore views
- Dashboard charts/stats screen using `fl_chart` (navigated from home dashboard)

## Assumptions

- MVP focused on operational workflow, not authentication/roles.
- Backend API is available on LAN and reachable from Android device.
- Device/host local time is used for due appointment behavior.

## AI Usage Disclosure (Summary)

AI assistance was used for iterative Flutter screen logic, UI refinements, workflow transitions, and debugging help.

Manual work included on-device testing, endpoint/IP validation, server checks, and acceptance/rejection of proposed UX behavior.

For full cross-repo disclosure (both chats), see the root documentation: `../README.md`.
