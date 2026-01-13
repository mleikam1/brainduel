import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryIconMapper {
  static IconData forCategory(Category category) {
    switch (category.id) {
      case 'sports':
        return Icons.sports_football;
      case 'history':
        return Icons.history_edu;
      case 'science':
        return Icons.science;
      case 'geography':
        return Icons.public;
      case 'movies':
        return Icons.movie;
      case 'music':
        return Icons.music_note;
      case 'entertainment':
        return Icons.movie;
      case 'food':
        return Icons.restaurant;
      case 'animals':
        return Icons.pets;
      case 'technology':
        return Icons.memory;
      case 'general':
        return Icons.quiz;
      default:
        final title = category.title.toLowerCase();
        if (title.contains('sport')) return Icons.sports_football;
        if (title.contains('history')) return Icons.history_edu;
        if (title.contains('science')) return Icons.science;
        if (title.contains('geo')) return Icons.public;
        if (title.contains('entertainment') || title.contains('movie')) return Icons.movie;
        if (title.contains('music')) return Icons.music_note;
        if (title.contains('food')) return Icons.restaurant;
        if (title.contains('animal')) return Icons.pets;
        if (title.contains('tech')) return Icons.memory;
        if (title.contains('general')) return Icons.quiz;
        return Icons.quiz;
    }
  }
}
