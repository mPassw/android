import 'package:mpass/auth/service/authorization_service.dart';
import 'package:mpass/dashboard/navigation/generator/state/passwords_generator_state.dart';
import 'package:pointycastle/export.dart';

class PasswordGenerator {
  static final _charset =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  static final _numberset = "0123456789";
  static final _symbolset = "!@#\$%^&*()_+";

  static int _getRandomNumber(int min, int max, FortunaRandom random) {
    int index = min + random.nextUint32() % (max - min + 1);
    return index;
  }

  static String _pickRandom(List<String> source, FortunaRandom random) {
    return source[_getRandomNumber(0, source.length - 1, random)];
  }

  static String _pickRandomChar(String source, FortunaRandom random) {
    int index = _getRandomNumber(0, source.length - 1, random);
    return source[index];
  }

  static String generatePassword(PasswordParams passwordParams) {
    int totalLength = passwordParams.passwordLength;
    int minNumbers = passwordParams.minimumNumbers;
    int minSymbols = passwordParams.minimumSymbols;

    FortunaRandom random = AuthorizationService.secureRandom();

    List<String> passwordChars = [];

    for (int i = 0; i < 2; i++) {
      passwordChars.add(_pickRandomChar(_charset, random));
    }

    for (int i = 0; i < minNumbers; i++) {
      passwordChars.add(_pickRandomChar(_numberset, random));
    }

    for (int i = 0; i < minSymbols; i++) {
      passwordChars.add(_pickRandomChar(_symbolset, random));
    }

    while (passwordChars.length < totalLength) {
      String pool = _charset;
      if (minNumbers > 0) pool += _numberset;
      if (minSymbols > 0) pool += _symbolset;
      passwordChars.add(_pickRandomChar(pool, random));
    }

    for (int i = passwordChars.length - 1; i > 0; i--) {
      int j = random.nextUint32() % (i + 1);
      String temp = passwordChars[i];
      passwordChars[i] = passwordChars[j];
      passwordChars[j] = temp;
    }

    return passwordChars.join();
  }

  static String generatePassphrase(
      PassphraseParams passphraseParams, List<String> wordsList) {
    int passphraseLength = passphraseParams.passphraseLength;
    bool includeNumber = passphraseParams.includeNumber;
    bool capitalize = passphraseParams.capitalize;
    String separator = passphraseParams.separator;

    FortunaRandom random = AuthorizationService.secureRandom();

    List<String> selectedWords = List.generate(
      passphraseLength,
      (index) => _pickRandom(wordsList, random),
    );

    if (capitalize) {
      selectedWords = selectedWords
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .toList();
    }

    if (includeNumber) {
      int randomIndex = _getRandomNumber(0, selectedWords.length - 1, random);
      selectedWords[randomIndex] += _getRandomNumber(0, 10, random).toString();
    }

    return selectedWords.join(separator);
  }

  static String generateUsername(
      UsernameParams usernameParams, List<String> wordsList) {
    bool includeNumber = usernameParams.includeNumber;
    bool capitalize = usernameParams.capitalize;

    FortunaRandom random = AuthorizationService.secureRandom();

    String selectedWord = _pickRandom(wordsList, random);

    if (capitalize) {
      selectedWord = selectedWord[0].toUpperCase() + selectedWord.substring(1);
    }

    if (includeNumber) {
      String randomNumber = "";
      while (randomNumber.length < 4) {
        randomNumber += _getRandomNumber(0, 10, random).toString();
      }
      selectedWord += randomNumber;
    }

    return selectedWord;
  }

  static String generateEmail(EmailParams emailParams) {
    String email = emailParams.email;
    if (email.isEmpty) {
      email = "undefined@undefined";
    } else if (!email.contains("@")) {
      email = "$email@undefined";
    }
    List<String> parts = emailParams.email.split('@');
    if (parts.length < 2) {
      parts.add("undefined");
    }
    String name = parts[0];
    String domain = parts[1];

    FortunaRandom random = AuthorizationService.secureRandom();
    String randomCharacters = "";
    while (randomCharacters.length < 6) {
      randomCharacters += _pickRandomChar(_charset + _numberset, random);
    }

    return "$name+$randomCharacters@$domain";
  }
}
