class ContactsService {
  Future<List<String>> loadPhoneNumbers() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return const [];
  }
}
