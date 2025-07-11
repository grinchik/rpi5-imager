# https://ubuntu.com/download/raspberry-pi
IMAGE_URL = https://cdimage.ubuntu.com/releases/24.04.2/release/ubuntu-24.04.2-preinstalled-server-arm64+raspi.img.xz

IMAGE_FILENAME_COMPRESSED = $(notdir $(IMAGE_URL))
IMAGE_FILENAME = $(basename $(IMAGE_FILENAME_COMPRESSED))
USER_DATA_TEMPLATE_FILEPATH = src/user-data.template.yaml
USER_DATA_FILEPATH = system-boot/user-data
MOUNT_FILEPATH = /Volumes/system-boot/

.PHONY: _
_: \
	$(IMAGE_FILENAME) \
	$(USER_DATA_FILEPATH) \
	confirm \
	unmount \
	flash \
	sync \
	copy \
	sync \
	unmount \
	notify \
	/

$(IMAGE_FILENAME_COMPRESSED): \
	/
	curl \
		--output \
			"$(IMAGE_FILENAME_COMPRESSED)" \
		"$(IMAGE_URL)" \
		;

$(IMAGE_FILENAME): \
	$(IMAGE_FILENAME_COMPRESSED) \
	/
	gunzip \
		--suffix \
			.xz \
		--keep \
		--verbose \
		--force \
		"$(IMAGE_FILENAME_COMPRESSED)" \
		;

$(USER_DATA_FILEPATH): \
	$(SSH_PUBLIC_KEY_FILEPATH) \
	$(USER_DATA_TEMPLATE_FILEPATH) \
	/
	SSH_PUBLIC_KEY="$(shell cat $(SSH_PUBLIC_KEY_FILEPATH))" \
		envsubst \
			< "$(USER_DATA_TEMPLATE_FILEPATH)" \
			> "$(USER_DATA_FILEPATH)" \
		;

.PHONY: disk-list
disk-list: \
	/
	@diskutil \
		list \
			"$(DISK_FILEPATH)" \
		;

.PHONY: confirm
confirm: \
	disk-list \
	/
	@CONFIRMATION_KEY="YES"; \
	echo "Type $$CONFIRMATION_KEY to continue:"; \
	read LINE; \
	if [ "$$LINE" != "$$CONFIRMATION_KEY" ]; then exit 1; fi

.PHONY: unmount
unmount: \
	/
	diskutil \
		unmountDisk \
			"$(DISK_FILEPATH)" \
		;

.PHONY: flash
flash: \
	/
	ls \
		-l \
			"$(IMAGE_FILENAME)" \
		;

	dd \
		if="$(IMAGE_FILENAME)" \
		of="$(DISK_FILEPATH)" \
		status=progress \
		bs=4m \
		;

.PHONY: sync
sync: \
	/
	sync;
	sleep 3;

.PHONY: copy
copy: \
	/
	rsync \
		--archive \
		--verbose \
		--exclude=".gitignore" \
		--exclude=".DS_Store" \
		"$(dir $(USER_DATA_FILEPATH))" \
		"$(MOUNT_FILEPATH)" \
		;

.PHONY: notify
notify: \
	/
	osascript \
		-e \
			beep \
		;

.PHONY: clean
clean: \
	/
	rm \
		-f \
		"$(IMAGE_FILENAME_COMPRESSED)" \
		"$(IMAGE_FILENAME)" \
		"$(USER_DATA_FILEPATH)" \
		;
