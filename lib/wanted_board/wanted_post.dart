/// One WantedPost returned by the Django serializer.
class WantedPost {
  const WantedPost({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    required this.location,
    required this.requester,
    required this.requesterUsername,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  // DRF returns decimals as strings. Older posts may have a null budget.
  final String? budget;
  final String location;
  final int requester;
  final String requesterUsername;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory WantedPost.fromJson(Map<String, dynamic> json) {
    return WantedPost(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      budget: json['budget']?.toString(),
      location: json['location'] as String,
      requester: json['requester'] as int,
      requesterUsername: json['requester_username'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Response for GET /wanted-post/api/?page=1.
class WantedPostPage {
  const WantedPostPage({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<WantedPost> results;

  factory WantedPostPage.fromJson(Map<String, dynamic> json) {
    return WantedPostPage(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List)
          .map((item) => WantedPost.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WantedCategory {
  const WantedCategory({required this.value, required this.label});

  final String value;
  final String label;

  factory WantedCategory.fromJson(Map<String, dynamic> json) {
    return WantedCategory(
      value: json['value'] as String,
      label: json['label'] as String,
    );
  }
}

/// Fetch once for each new form, then reuse creationToken when retrying submit.
class WantedCreateOptions {
  const WantedCreateOptions({
    required this.creationToken,
    required this.csrfToken,
    required this.categories,
  });

  final String creationToken;
  final String csrfToken;
  final List<WantedCategory> categories;

  factory WantedCreateOptions.fromJson(Map<String, dynamic> json) {
    return WantedCreateOptions(
      creationToken: json['creation_token'] as String,
      csrfToken: json['csrf_token'] as String,
      categories: (json['categories'] as List)
          .map((item) => WantedCategory.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
