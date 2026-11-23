*&---------------------------------------------------------------------*
*& Report ZTEST_PO_LOGO
*&---------------------------------------------------------------------*
*& Calls the same method used in the form interface (Code Initialization)
*& of ZMM_F_EXTERNALPO_TRYSH for the NADFOOD logos and shows:
*&   - whether each graphic is found in SE78 (sy-subrc)
*&   - its size in bytes
*&   - whether two names return the SAME image (e.g. 2400 = 5000)
*& Optional: downloads each image as .BMP to the PC to open and look at it.
*&---------------------------------------------------------------------*
REPORT ztest_po_logo.

PARAMETERS: p_n1   TYPE tdobname DEFAULT '2400',
            p_n2   TYPE tdobname DEFAULT 'ISO2400',
            p_n3   TYPE tdobname DEFAULT '5000',
            p_n4   TYPE tdobname DEFAULT 'ISO5000',
            p_dl   AS CHECKBOX DEFAULT ' ',
            p_path TYPE string LOWER CASE DEFAULT 'C:\TEMP\'.

TYPES: BEGIN OF ty_res,
         name  TYPE tdobname,
         subrc TYPE sy-subrc,
         len   TYPE i,
         bmp   TYPE xstring,
       END OF ty_res.

DATA: lt_names TYPE STANDARD TABLE OF tdobname,
      lv_name  TYPE tdobname,
      lt_res   TYPE STANDARD TABLE OF ty_res,
      ls_res   TYPE ty_res,
      ls_cmp   TYPE ty_res,
      lv_text  TYPE char20,
      lv_same  TYPE string,
      lt_bin   TYPE STANDARD TABLE OF x255,
      lv_size  TYPE i,
      lv_file  TYPE string.

START-OF-SELECTION.

  APPEND p_n1 TO lt_names.
  APPEND p_n2 TO lt_names.
  APPEND p_n3 TO lt_names.
  APPEND p_n4 TO lt_names.
  DELETE lt_names WHERE table_line IS INITIAL.

* Same call as in the form interface
  LOOP AT lt_names INTO lv_name.
    CLEAR ls_res.
    ls_res-name = lv_name.
    CALL METHOD cl_ssf_xsf_utilities=>get_bds_graphic_as_bmp
      EXPORTING
        p_object       = 'GRAPHICS'
        p_name         = lv_name
        p_id           = 'BMAP'
        p_btype        = 'BCOL'
      RECEIVING
        p_bmp          = ls_res-bmp
      EXCEPTIONS
        not_found      = 1
        internal_error = 2
        OTHERS         = 3.
    ls_res-subrc = sy-subrc.
    ls_res-len   = xstrlen( ls_res-bmp ).
    APPEND ls_res TO lt_res.
  ENDLOOP.

* Output
  WRITE: / 'Name', 15 'Result', 37 'Size (bytes)', 55 'Same image as'.
  ULINE.
  LOOP AT lt_res INTO ls_res.
    CASE ls_res-subrc.
      WHEN 0.    lv_text = 'OK'.
      WHEN 1.    lv_text = 'NOT FOUND'.
      WHEN 2.    lv_text = 'INTERNAL ERROR'.
      WHEN OTHERS. lv_text = 'ERROR'.
    ENDCASE.

    CLEAR lv_same.
    IF ls_res-len > 0.
      LOOP AT lt_res INTO ls_cmp WHERE name <> ls_res-name.
        IF ls_cmp-bmp = ls_res-bmp.
          CONCATENATE lv_same ls_cmp-name INTO lv_same SEPARATED BY space.
        ENDIF.
      ENDLOOP.
    ENDIF.

    WRITE: / ls_res-name, 15 lv_text, 37 ls_res-len, 55 lv_same.
  ENDLOOP.

* Optional: download images to the PC to view them
  IF p_dl = 'X'.
    LOOP AT lt_res INTO ls_res WHERE len > 0.
      CLEAR: lt_bin, lv_size.
      CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
        EXPORTING
          buffer        = ls_res-bmp
        IMPORTING
          output_length = lv_size
        TABLES
          binary_tab    = lt_bin.

      CONCATENATE p_path ls_res-name '.bmp' INTO lv_file.
      CALL METHOD cl_gui_frontend_services=>gui_download
        EXPORTING
          bin_filesize = lv_size
          filename     = lv_file
          filetype     = 'BIN'
        CHANGING
          data_tab     = lt_bin
        EXCEPTIONS
          OTHERS       = 1.
      IF sy-subrc = 0.
        WRITE: / 'Downloaded:', lv_file.
      ELSE.
        WRITE: / 'Download failed:', lv_file.
      ENDIF.
    ENDLOOP.
  ENDIF.
