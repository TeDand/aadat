/// Bump [kAppVersion] and add an entry here whenever you push to main.
/// Keep this in sync with the version in pubspec.yaml.
const String kAppVersion = '0.1.0';

enum ChangeType { feature, fix }

class ChangeEntry {
  final ChangeType type;
  final String description;
  const ChangeEntry(this.type, this.description);
}

/// Changes currently on the dev branch that have not yet shipped to users.
/// Add entries here as you build. When releasing, move them into [kChangelog]
/// under the new version key and clear this list.
const List<ChangeEntry> kDevChangelog = [
  // Example:
  // ChangeEntry(ChangeType.feature, 'Something being built on dev'),
];

/// Maps version strings to the list of changes introduced in that version.
/// The popup shows the entry for [kAppVersion] whenever a user updates.
const Map<String, List<ChangeEntry>> kChangelog = {
  '0.1.0': [
    ChangeEntry(ChangeType.feature, 'Custom recurrence — pick specific days of the week for a habit'),
    ChangeEntry(ChangeType.feature, 'Day notes — attach a note to any habit on any day in the Calendar'),
    ChangeEntry(ChangeType.feature, 'About page'),
    ChangeEntry(ChangeType.fix, 'End date is now validated against the habit start date'),
  ],
};
