# Xiaomi Redmi Note 4 — Nikel

[English](README.md) | Русский

Дерево устройства для LineageOS 13.0 на Android 6.0.1, платформа MediaTek MT6797.
Продукт сборки — `lineage_nikel`, архитектуры — ARM64 и ARM32.
Дерево развивается поэтапно, с отдельными коммитами для подсистем.

Проверены выбор продукта через `lunch`, сборка контрольного `boot.img`, приложения
FMRadio, библиотек телефонии и нативных зависимостей. Проверки загрузки, камеры,
звука, связи, FM, отпечатка и шифрования на телефоне ещё предстоят.

Пользовательская часть отпечатка включает FPC и Goodix. Готовое ядро в этом дереве
собрано с поддержкой Goodix. Для FPC потребуется соответствующая конфигурация ядра.
В вариантах `userdebug` и `eng` домены `mtk_daemon` и `fingerprintd` работают
в permissive для сбора отказов SELinux при первоначальном запуске.

## Структура

| Файл или каталог | Назначение |
|---|---|
| `BoardConfig.mk` | MT6797, ABI, параметры загрузочного образа и разделов |
| `lineage.mk`, `full_nikel.mk`, `device.mk` | Продукт, пакеты и установка файлов |
| `rootdir/` | Init-сервисы, fstab и права устройств |
| `configs/`, `audio/`, `gps/`, `wifi/` | Конфигурации подсистем |
| `overlay/` | Настройки ресурсов Android для Nikel |
| `sepolicy/` | Дополнения политики SELinux |
| `ril-cm13/` | Адаптер MediaTek RIL для API телефонии CM13 |
| `prebuilt/kernel` | Ядро в формате `Image.gz-dtb` |
| `proprietary-blobs.txt` | Список блобов, сгруппированный по подсистемам |
| `patches/` | Изменения платформы, необходимые этому дереву |
| `tools/` | Проверка vendor-файлов и загрузочного образа |

## Исходники и окружение

Дерево размещается в `device/xiaomi/nikel`, vendor — в `vendor/xiaomi/nikel`.
Для платформы используется ветка `cm-13.0`. Все команды ниже выполняются из корня
исходников LineageOS.

Для сборки используются JDK 8 и инструменты эпохи Android 6. Старым скриптам
Java-сборки нужен Python 2.7 под именем `python`. Скрипты из `tools/` запускаются
через Python 3 и используют `readelf`.

При проверке на современном Linux для legacy Jack понадобилась обёртка `curl`,
заменяющая аргумент `--no-proxy` на `--noproxy`. В текущем локальном окружении
обёртка и ссылка `python` на Python 2 находятся в
`/home/ma3axata/nikel-validation/python2-bin`. Этот каталог можно добавить в начало
`PATH` перед запуском Java-сборки.

Готовое ядро собрано из коммита `70e2df0c7b9efa37b920a291ad6e32ac92d4ca98`
с `nikel_defconfig` и GCC 4.9 из ALPS. Источник блобов — распакованный сток Nikel
MIUI `V10.2.1.0.MBFMIXM`, Android 6.0.

Исходники ядра доступны в репозитории проекта.
[RM4-Nikel/android_kernel_xiaomi_nikel](https://github.com/RM4-Nikel/android_kernel_xiaomi_nikel)

## Патчи платформы

Для чистого дерева CM13 нужны следующие патчи. В текущем рабочем дереве они уже
применены. Перед применением к другой ревизии проверь каждый через `git apply --check`.

| Патч | Репозиторий | Назначение |
|---|---|---|
| `system-core-mtk-init.patch` | `system/core` | Окружение MTK RIL и отключение запуска стандартного rild |
| `system-core-mtk-ril.patch` | `system/core` | Сетевые ioctl CCMNI для MediaTek RIL |
| `frameworks-av-camera-flip.patch` | `frameworks/av` | Символы `CameraParameters`, используемые стоковой камерой |
| `tinycompress-prebuilt-kernel.patch` | `external/tinycompress` | Использование UAPI-заголовков Bionic при готовом ядре Nikel |

Например, из корня CM13 можно проверить и применить патч камеры.

```bash
git -C frameworks/av apply --check ../../device/xiaomi/nikel/patches/frameworks-av-camera-flip.patch
git -C frameworks/av apply ../../device/xiaomi/nikel/patches/frameworks-av-camera-flip.patch
```

## Работа с vendor

`proprietary-blobs.txt` содержит пути относительно `system/` стокового дампа.
Запись `source:destination` задаёт другое имя при установке. Общие зависимости
сгруппированы по основной роли. Назначение отдельных UUID-файлов Trustonic
пока требует уточнения.

Для извлечения файлов укажи каталог дампа, содержащий `system/`.

```bash
device/xiaomi/nikel/extract-files.sh /path/to/stock-dump
python3 device/xiaomi/nikel/tools/audit-vendor.py /path/to/stock-dump
```

Извлечение заменяет перечисленные файлы их стоковыми версиями. Аудит сравнивает
хеши со стоком и проверяет пути vendor-зависимостей ELF с учётом ABI.
Совместимость символов платформы и работу оборудования проверяют отдельно.

Для ручного добавления блоба дополни список, положи файл в соответствующий путь
под `vendor/xiaomi/nikel/proprietary/` и пересоздай makefile.

```bash
device/xiaomi/nikel/setup-makefiles.sh
git -C device/xiaomi/nikel diff
git -C vendor/xiaomi/nikel diff
git -C vendor/xiaomi/nikel status --short
```

`setup-makefiles.sh` сохраняет содержимое блобов. Намеренно изменённая библиотека
даст отличие хеша при сравнении со стоком. Изменения списка и vendor-файлов
фиксируются в соответствующих Git-репозиториях.

## Контрольная сборка

```bash
export LC_ALL=C
source build/envsetup.sh
lunch lineage_nikel-userdebug
make -j4 bootimage
python3 device/xiaomi/nikel/tools/verify-boot.py out/target/product/nikel/boot.img
```

Проверка образа сверяет заголовок Android, контрольную сумму, ядро, добавленный
DTB и необходимые файлы initramfs. Результат сборки находится в
`out/target/product/nikel/boot.img`.

FMRadio собирается отдельной целью после подготовки окружения Java-сборки.

```bash
make -j4 FMRadio
```

Для сравнения с другим ядром можно задать `TARGET_PREBUILT_KERNEL` при сборке.
Ядро должно иметь формат gzip с добавленным DTB. Скрипт `verify-boot.py` сверяет
образ с `prebuilt/kernel` из этого дерева.

```bash
make -j4 bootimage TARGET_PREBUILT_KERNEL=/path/to/Image.gz-dtb
```

Размер раздела boot в стоковом scatter — 16 МиБ. Работу раздела `/data`,
существующего шифрования, загрузчика и аппаратных вариантов предстоит проверить
на устройстве. Полная сборка прошивки остаётся следующим этапом.

Адаптер RIL и его исходный патч CCMNI взяты из дерева CoreXGT для CM13
с сохранением авторских заголовков. FMRadio используется из исходников CM13.
[CoreXGT Nikel cm-13.0](https://github.com/CoreXGT/android_device_xiaomi-nikel-lineage-14.1/tree/cm-13.0)
