icon_sizes = ['128', '256']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
    install_data(
        join_paths('icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps')
    )
endforeach


install_data(
    'resources' / 'compress.svg',
    install_dir: get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps'
)
install_data(
    'resources' / 'split.svg',
    install_dir: get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps'
)
install_data(
    'resources' / 'merge.svg',
    install_dir: get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps'
)
install_data(
    'resources' / 'convert.svg',
    install_dir: get_option('datadir') / 'icons' / 'hicolor' /'scalable' / 'apps'
)






#======== Internationalization ========
#Translate and install our .desktop file
i18n.merge_file(
    input: 'pdftricks.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: meson.project_source_root() / 'po' / 'extra',
    type: 'desktop',
    install: true,
    install_dir: get_option('datadir') / 'applications'
)

#======== Metainfo ========
#Translate and install our .metainfo file
i18n.merge_file(
    input: 'pdftricks.metainfo.xml.in',
    output: meson.project_name() + '.metainfo.xml',
    po_dir: meson.project_source_root() / 'po' / 'extra',
    install: true,
    install_dir: get_option('datadir') / 'metainfo'
)
