# project name and programming language
project(
    'com.github.muriloventuroso.pdftricks',
    'vala',
    'c',
    version: '0.2.3')

add_project_arguments([
        '-DGETTEXT_PACKAGE=\"@0@\"'.format(meson.project_name())
    ],
    language: 'c',
)

i18n = import('i18n')
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language:'c')

dependencies = [
    dependency('gio-unix-2.0', version: '>=2.20'),
    dependency('granite'),
]

config_data = configuration_data()
config_data.set('EXEC_NAME', meson.project_name())



conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))
config_header = configure_file(
    input : 'config.vala.in',
    output : 'config.vala',
    configuration : conf_data
)

message ('Adds files to build')

code_files = files(
    'src/Application.vala',
    'src/Widgets/Welcome.vala',
    'src/Widgets/CompressPDF.vala',
    'src/Widgets/SplitPDF.vala',
    'src/Widgets/MergePDF.vala',
    'src/Widgets/ConvertPDF.vala'
)

message ('Defines executable')

executable(
    meson.project_name(),
    code_files,
    config_header,
    dependencies: dependencies,
    install: true
)
subdir('data')
subdir('po')

