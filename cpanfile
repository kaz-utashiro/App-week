requires 'perl', '5.014';

requires 'Getopt::EX', 'v1.23.3';
requires 'Getopt::EX::termcolor', '1.06';
requires 'Getopt::EX::i18n', '0.09';
requires 'Text::VisualWidth::PP', '0.05';
requires 'Text::ANSI::Fold', '2.10';
requires 'Date::Japanese::Era';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

