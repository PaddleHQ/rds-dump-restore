SET_LAMBDA=db_set_data
CHECK_LAMBDA=db_check_data

zipfiles: $(SET_LAMBDA).zip $(CHECK_LAMBDA).zip

base_libraries.zip:
	mkdir -p libraries
	pip install -t libraries -r requirements.txt
	cd libraries ; \
		zip -r ../base_libraries.zip .

$(SET_LAMBDA).zip: base_libraries.zip $(SET_LAMBDA).py
	zip base_libraries.zip -O $(SET_LAMBDA).zip $(SET_LAMBDA).py

$(CHECK_LAMBDA).zip: base_libraries.zip $(SET_LAMBDA).py
	zip base_libraries.zip -O $(CHECK_LAMBDA).zip $(CHECK_LAMBDA).py

.PHONY: zipfiles base_libraries.zip
