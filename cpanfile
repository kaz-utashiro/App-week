requires 'perl', '5.014';

requires 'Getopt::EX', 'v1.19.0';
requires 'Getopt::EX::termcolor', '1.06';
requires 'Getopt::EX::i18n', '0.08';
requires 'Text::VisualWidth::PP', '0.05';
requires 'Text::ANSI::Fold', '1.03';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

