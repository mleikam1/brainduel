enum CategoryWeeklyState { fresh, completed }

class CategoryWeeklyIndicator {
  final CategoryWeeklyState? state;
  final bool showWeeklyRefresh;

  const CategoryWeeklyIndicator({
    this.state,
    this.showWeeklyRefresh = false,
  });
}
