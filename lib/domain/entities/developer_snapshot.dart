import 'github_profile.dart';
import 'github_repository.dart';

class DeveloperSnapshot {
  const DeveloperSnapshot({
    required this.profile,
    required this.repository,
  });

  final GitHubProfile profile;
  final GitHubRepository repository;
}
