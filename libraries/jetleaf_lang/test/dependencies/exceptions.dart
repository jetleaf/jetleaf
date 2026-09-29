import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

const isInvalidArgumentException = TypeMatcher<InvalidArgumentException>();
Matcher throwsInvalidArgumentException = throwsA(isInvalidArgumentException);

const isIllegalArgumentException = TypeMatcher<IllegalArgumentException>();
Matcher throwsIllegalArgumentException = throwsA(isIllegalArgumentException);

const isInvalidFormatException = TypeMatcher<InvalidFormatException>();
Matcher throwsInvalidFormatException = throwsA(isInvalidFormatException);

const isNoGuaranteeException = TypeMatcher<NoGuaranteeException>();
Matcher throwsNoGuaranteeException = throwsA(isNoGuaranteeException);