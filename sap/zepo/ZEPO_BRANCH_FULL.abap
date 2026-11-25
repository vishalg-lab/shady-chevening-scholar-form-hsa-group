*----------------------------------------------------------------------*
* ZEPO / ZCOP / ZNPO branch of FORM entry_neu  (driver: ZMM_PO_DRIVER_MAIN)
* Replace the WHOLE branch in SAP: from the line
*   ELSEIF doc_type EQ 'ZEPO'   OR Doc_type EQ 'ZCOP'  OR Doc_type EQ 'ZNPO'  .
* up to (NOT including) the line
*   ELSEIF doc_type EQ 'ZAPO' .
* All changes inside are marked COPY FROM HERE / COPY TILL HERE and "<<< NEW.
*----------------------------------------------------------------------*
  ELSEIF doc_type EQ 'ZEPO'   OR Doc_type EQ 'ZCOP'  OR Doc_type EQ 'ZNPO'  .
*  *ZMM_ST_EXTERNALPO   ----     ZMM_ST_MD_EXTERNALPO
    DATA : hd23          TYPE zmm_st_externalpo,
           it23          TYPE zmm_tt_externalpo,
           it23_d        TYPE  zmm_tt_externalpo,
           wa23          TYPE LINE OF zmm_tt_externalpo,
           wa23_d        TYPE LINE OF zmm_tt_externalpo,
           pg            TYPE ekko-ekgrp,
           adrnr23       TYPE lfa1-adrnr,
           total23       TYPE netwr,
           total_words23 TYPE spell,
           fraction23    TYPE netwr,
           decimal23     TYPE num2,
           textt23       TYPE TABLE OF tline, texts23 TYPE tdline,textf23 TYPE znote2,
           name23        TYPE thead-tdname,
*       LANG TYPE THEAD-TDSPRAS,
           Amount23      TYPE wrbtr.

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*>>> GRADE NO - CHANGE 1 of 4 (DECLARATIONS)  ---  COPY FROM HERE
*>>> Paste after:  Amount23      TYPE wrbtr.
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
* GRADE NO column (replaces Manufacturer Part No. for company 1700)
* All conditions must be true for an item:
*   EKKO-BSART = ZEPO, EKPO-BUKRS = 1700, EKPO-WERKS = 1710/1712/1713,
*   EKPO-BSTYP = F,    EKPO-MTART = ZROH/ZPCK
* Then the column title becomes GRADE NO and the value is EKPO-BEDNR (10 chars).
    DATA: BEGIN OF ls_grd23,                            "<<< NEW
            bukrs TYPE ekpo-bukrs,                      "<<< NEW
            werks TYPE ekpo-werks,                      "<<< NEW
            bstyp TYPE ekpo-bstyp,                      "<<< NEW
            mtart TYPE ekpo-mtart,                      "<<< NEW
            bednr TYPE ekpo-bednr,                      "<<< NEW
          END OF ls_grd23,                              "<<< NEW
          lv_grd_item23 TYPE abap_bool,                 "<<< NEW
          lv_grd_cnt23  TYPE i,                         "<<< NEW
          lv_itm_cnt23  TYPE i.                         "<<< NEW
    CLEAR: lv_grd_cnt23, lv_itm_cnt23.                  "<<< NEW
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*<<< GRADE NO - CHANGE 1 of 4 (DECLARATIONS)  ---  COPY TILL HERE
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    total23 = 0 .
    BREAK aalmansoub.
    hd23-ebeln = doc_no.
    BREAK abapcon01 .
    BREAK aalmansoub.
* GET HEADER DATA OF LOCAL PO FORM
    SELECT SINGLE bedat lifnr bukrs waers  inco1 inco2 verkf FROM ekko INTO CORRESPONDING FIELDS OF hd23
      WHERE ebeln EQ hd23-ebeln .
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*>>> OUR REF  ---  COPY FROM HERE
*>>> Paste after the SELECT SINGLE bedat lifnr ... FROM ekko above.
*>>> "Our Ref" on the printout = EKKO-IHREZ (ME23N > Header > Communication > Your Reference).
*>>> Stored in the existing field HD-UNSEZ (same length CHAR 12), so no DDIC / form change:
*>>> the form field "Our Ref" is already bound to $.HD.UNSEZ.
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    SELECT SINGLE ihrez FROM ekko INTO hd23-unsez                     "<<< NEW (Our Ref = EKKO-IHREZ)
      WHERE ebeln EQ hd23-ebeln .                                     "<<< NEW
*<<< OUR REF  ---  COPY TILL HERE
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    SELECT SINGLE spras FROM ekko INTO lang WHERE  ebeln EQ hd23-ebeln .
    SELECT SINGLE name1 name2 adrnr FROM lfa1 INTO ( hd23-name1 , hd23-name2 , adrnr23 )
      WHERE lifnr EQ hd23-lifnr .

*SELECT SINGLE VERKF FROM LFM1 INTO HD23-VERKF WHERE LIFNR EQ HD23-LIFNR.

    CONCATENATE hd23-inco1 hd23-inco2 INTO hd23-inco_terms SEPARATED BY ' , '.
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*>>> VENDOR NAME DUPLICATE FIX  ---  COPY FROM HERE
*>>> Replaces the line:
*>>>   CONCATENATE hd23-name1 hd23-name2 INTO hd23-vendor_name SEPARATED BY ' ' .
*>>> Many vendors (YCIC / YCPMI) have the same name in LFA1-NAME1 and NAME2,
*>>> so the supplier name was printed twice. NAME2 is added only when it
*>>> is not already part of NAME1 (CS = contains, not case sensitive).
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*   CONCATENATE hd23-name1 hd23-name2 INTO hd23-vendor_name SEPARATED BY ' ' .   "<<< OLD
    IF hd23-name2 IS INITIAL OR hd23-name1 CS hd23-name2.            "<<< NEW
      hd23-vendor_name = hd23-name1.                                  "<<< NEW  NAME2 empty or already in NAME1
    ELSEIF hd23-name2 CS hd23-name1.                                  "<<< NEW
      hd23-vendor_name = hd23-name2.                                  "<<< NEW  NAME2 already holds the full name
    ELSE.                                                             "<<< NEW
      CONCATENATE hd23-name1 hd23-name2                               "<<< NEW
             INTO hd23-vendor_name SEPARATED BY ' ' .                 "<<< NEW
    ENDIF.                                                            "<<< NEW
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*<<< VENDOR NAME DUPLICATE FIX  ---  COPY TILL HERE
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*------------------------------------------------------------------------
    SELECT SINGLE ekgrp FROM ekko  INTO pg WHERE ebeln EQ hd23-ebeln.
    IF pg EQ 'P02' .
      hd23-title = 'Raw Material'.
    ELSEIF pg EQ 'P03' .
      hd23-Title = 'Spare Parts'.
    ELSEIF pg EQ 'P13' OR pg EQ 'P15' OR pg EQ 'P17' OR pg EQ 'P19' OR
           pg EQ 'P21' OR pg EQ 'P23' OR pg EQ 'P25' OR pg EQ 'P27'.
      hd23-title = 'Materials'.
    ENDIF .






    BREAK aalmansoub.
*  Find Notes
    name23 = hd23-ebeln .
*LANG = 'EN'.  "---
* To get Header Text 1 .
    REFRESH textt23.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
*       CLIENT                  = SY-MANDT
        id                      = 'F23'
        language                = lang
        name                    = name23
        object                  = 'EKKO'
*       ARCHIVE_HANDLE          = 0
*       LOCAL_CAT               = ' '
* IMPORTING
*       HEADER                  =
*       OLD_LINE_COUNTER        =
      TABLES
        lines                   = textt23
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    texts23 = ''.
    textf23 = ''.
* To find Text Note
    LOOP AT textt23 INTO texts23.
      CONCATENATE textf23  texts23 INTO textf23 SEPARATED BY ' '.
    ENDLOOP.
    hd23-header_text_1 = textf23 .
    REPLACE ALL OCCURRENCES OF SUBSTRING '*' IN hd23-header_text_1 WITH ''.
    REPLACE ALL OCCURRENCES OF SUBSTRING '<(>' IN hd23-header_text_1 WITH ''.
    REPLACE ALL OCCURRENCES OF SUBSTRING '<)>' IN hd23-header_text_1 WITH ''.
*----------------------------------------
* To Get Header Text2

    REFRESH textt23.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
*       CLIENT                  = SY-MANDT
        id                      = 'F24'
        language                = lang
        name                    = name23
        object                  = 'EKKO'
*       ARCHIVE_HANDLE          = 0
*       LOCAL_CAT               = ' '
* IMPORTING
*       HEADER                  =
*       OLD_LINE_COUNTER        =
      TABLES
        lines                   = textt23
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    texts23 = ''.
    textf23 = ''.
* To find Text Note
    LOOP AT textt23 INTO texts23.
      CONCATENATE textf23  texts23 INTO textf23 SEPARATED BY ' '.
    ENDLOOP.
    hd23-header_text_2 = textf23 .
    REPLACE ALL OCCURRENCES OF SUBSTRING '*' IN hd23-header_text_2 WITH ''.
    REPLACE ALL OCCURRENCES OF SUBSTRING '<(>' IN hd23-header_text_2 WITH ''.
    REPLACE ALL OCCURRENCES OF SUBSTRING '<)>' IN hd23-header_text_2 WITH ''.


*  -----------------------------------------------------------------
    DATA : pg23       TYPE cvi_vend_link-partner_guid,
           addrcom23  TYPE but000-addrcomm,
           addrnumber TYPE t001-adrNR.
    BREAK aalmansoub.
    SELECT SINGLE  partner_guid FROM cvi_vend_link  INTO pg23 WHERE vendor EQ  hd23-lifnr.

    SELECT SINGLE addrcomm FROM but000 INTO addrcom23 WHERE partner_guid = pg23.
    SELECT SINGLE smtp_addr FROM adr6 INTO  hd23-smtp_addr WHERE addrnumber EQ addrcom23.
    SELECT SINGLE fax_number tel_number FROM adrc INTO (hd23-fax_number, hd23-tel_number) WHERE addrnumber EQ addrcom23.


*   Find Header data
    SELECT SINGLE adrnr FROM t001 INTO addrnumber WHERE bukrs EQ hd23-bukrs.   ""  fOR hEADEER
*H-ADDRNUMBER = FT-ADRNR.
    SELECT SINGLE sort1 FROM adrc INTO hd23-ccname
      WHERE addrnumber EQ addrnumber .

    BREAK abapcon01.

*----------------------------------------------------------------------------
* To Get PO Header Text

    REFRESH textt23.
    CALL FUNCTION 'READ_TEXT'
      EXPORTING
*       CLIENT                  = SY-MANDT
        id                      = 'F07'
        language                = lang
        name                    = name23
        object                  = 'EKKO'
*       ARCHIVE_HANDLE          = 0
*       LOCAL_CAT               = ' '
* IMPORTING
*       HEADER                  =
*       OLD_LINE_COUNTER        =
      TABLES
        lines                   = textt23
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    texts23 = ''.
    textf23 = ''.
* To find Text Note
    LOOP AT textt23 INTO texts23.
      CONCATENATE textf23  texts23 INTO textf23 SEPARATED BY ' '.
    ENDLOOP.
    hd23-po_hd_text = textf23 .
    REPLACE ALL OCCURRENCES OF SUBSTRING '*' IN hd23-po_hd_text WITH ''.
    REPLACE ALL OCCURRENCES OF SUBSTRING '<(>' IN hd23-po_hd_text WITH ''.
    REPLACE ALL OCCURRENCES OF SUBSTRING '<)>' IN hd23-po_hd_text WITH ''.
* ----------------------------------------------------------------------------
*  * To Get MODE OF DELIVERY

    REFRESH textt23.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
*       CLIENT                  = SY-MANDT
        id                      = 'F05'
        language                = lang
        name                    = name23
        object                  = 'EKKO'
*       ARCHIVE_HANDLE          = 0
*       LOCAL_CAT               = ' '
* IMPORTING
*       HEADER                  =
*       OLD_LINE_COUNTER        =
      TABLES
        lines                   = textt23
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    texts23 = ''.
    textf23 = ''.
* To find Text Note
    LOOP AT textt23 INTO texts23.
      CONCATENATE textf23  texts23 INTO textf23 SEPARATED BY ' '.
    ENDLOOP.
    hd23-delivery_method = textf23 .
    REPLACE ALL OCCURRENCES OF SUBSTRING '*' IN hd23-delivery_method WITH ''.
    REPLACE ALL OCCURRENCES OF SUBSTRING '<(>' IN hd23-delivery_method WITH ''.
    REPLACE ALL OCCURRENCES OF SUBSTRING '<)>' IN hd23-delivery_method WITH ''.
*  -----------------------------------------------------------------------------
*  TO GET  TIME OF DELIVER

    REFRESH textt23.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
*       CLIENT                  = SY-MANDT
        id                      = 'F14'
        language                = lang
        name                    = name23
        object                  = 'EKKO'
*       ARCHIVE_HANDLE          = 0
*       LOCAL_CAT               = ' '
* IMPORTING
*       HEADER                  =
*       OLD_LINE_COUNTER        =
      TABLES
        lines                   = textt23
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    texts23 = ''.
    textf23 = ''.
* To find Text Note
    LOOP AT textt23 INTO texts23.
      CONCATENATE textf23  texts23 INTO textf23 SEPARATED BY ' '.
    ENDLOOP.
    hd23-delivery_time = textf23 .
    REPLACE ALL OCCURRENCES OF SUBSTRING '*' IN hd23-delivery_time WITH ''.
    REPLACE ALL OCCURRENCES OF SUBSTRING '<(>' IN hd23-delivery_time WITH ''.
    REPLACE ALL OCCURRENCES OF SUBSTRING '<)>' IN  hd23-delivery_time WITH ''.

    BREAK abapcon01 .
* ---------------------------------------------------------------------



    " This one reads the text FOR DOC SHADY ALMURISH
    REFRESH textt23.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
*       CLIENT                  = SY-MANDT
        id                      = 'F25'
        language                = lang
        name                    = name23
        object                  = 'EKKO'
*       ARCHIVE_HANDLE          = 0
*       LOCAL_CAT               = ' '
* IMPORTING
*       HEADER                  =
*       OLD_LINE_COUNTER        =
      TABLES
        lines                   = textt23
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    texts23 = ''.
    textf23 = ''.
* To find Text Note
    LOOP AT textt23 INTO texts23.
      CONCATENATE textf23  texts23 INTO textf23 SEPARATED BY SPACE ."' '. "cl_abap_char_utilities=>NEWLINE .
    ENDLOOP.
    hd23-doc_req = textf23 .
    REPLACE ALL OCCURRENCES OF SUBSTRING '*' IN hd23-doc_req WITH ''.
    REPLACE ALL OCCURRENCES OF SUBSTRING '<(>' IN hd23-doc_req WITH ''.
    REPLACE ALL OCCURRENCES OF SUBSTRING '<)>' IN hd23-doc_req WITH ''.

* EDITED BY SHADY Almuraish

* Fill clean-section nodes (centralized to avoid duplication)
    PERFORM fill_externalpo_section_nodes USING lang name23   CHANGING hd23.
*  ----------------------------------------------------------------------------

*  *  GET TABLE DATA OF MATERIAL
    BREAK aalmansoub.

    SELECT ebelp txz01 matnr meins menge netpr netwr peinh
      FROM ekpo INTO CORRESPONDING FIELDS OF wa23
      WHERE ebeln EQ hd23-ebeln  AND loekz EQ ''.  "ADDED BY ABDELRAHMAN AND KHALED ON 5.2.2020"
      total23 = total23 + wa23-netwr .
      wa23-waers = hd23-waers.
      wa23-waers2 = hd23-waers .
*SELECT SINGLE LOEKZ INTO LOEKZ FROM EKPO WHERE EBELN EQ HD23-EBELN . "ADDED BY ABDELRAHMAN AND KHALED ON 5.2.2020"

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*>>> GRADE NO - CHANGE 2 of 4 (CHECK CONDITIONS PER ITEM)  ---  COPY FROM HERE
*>>> Paste inside SELECT ... ENDSELECT, after:  wa23-waers2 = hd23-waers .
*>>> Must stay BEFORE  SHIFT wa23-ebelp  (EKPO-EBELP is NUMC 5, e.g. 00010).
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      lv_itm_cnt23 = lv_itm_cnt23 + 1.                                    "<<< NEW
      lv_grd_item23 = abap_false.                                         "<<< NEW
      CLEAR ls_grd23.                                                     "<<< NEW
      IF doc_type EQ 'ZEPO'.                                              "<<< NEW
        SELECT SINGLE bukrs werks bstyp mtart bednr                       "<<< NEW
          FROM ekpo                                                       "<<< NEW
          INTO CORRESPONDING FIELDS OF ls_grd23                           "<<< NEW
          WHERE ebeln EQ hd23-ebeln                                       "<<< NEW
            AND ebelp EQ wa23-ebelp.                                      "<<< NEW
        IF sy-subrc EQ 0                                                  "<<< NEW
          AND ls_grd23-bukrs EQ '1700'                                    "<<< NEW
          AND ( ls_grd23-werks EQ '1710' OR ls_grd23-werks EQ '1712'      "<<< NEW
                                         OR ls_grd23-werks EQ '1713' )    "<<< NEW
          AND ls_grd23-bstyp EQ 'F'                                       "<<< NEW
          AND ( ls_grd23-mtart EQ 'ZROH' OR ls_grd23-mtart EQ 'ZPCK' ).   "<<< NEW
          lv_grd_item23 = abap_true.                                      "<<< NEW
        ENDIF.                                                            "<<< NEW
      ENDIF.                                                              "<<< NEW
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*<<< GRADE NO - CHANGE 2 of 4 (CHECK CONDITIONS PER ITEM)  ---  COPY TILL HERE
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

      IF pg EQ 'P03'.
        SELECT SINGLE mfrpn FROM mara INTO wa23-mfrpn WHERE matnr EQ wa23-matnr .
      ENDIF.


      IF wa23-mfrpn IS INITIAL.
        IF ( ( doc_type = 'ZEPO' ) AND  ( pg = 'P01' OR Pg = 'P02' ) ).

          SELECT SINGLE ekpo~matnr INTO wa23-material
            FROM ekpo
            WHERE ebeln = hd23-ebeln
            AND ebelp = wa23-ebelp
            AND ekpo~mtart = 'ZPCK'
            AND ekpo~bukrs = '1000'
            AND ekpo~werks = '1010'.
*  AND EKPO~EKGRP = 'P01' and EKPO~EKGRP = 'P02'.

          CLEAR wa23-mfrpn.
          SHIFT wa23-material LEFT DELETING LEADING '0'.
          wa23-mfrpn = wa23-material.
          CLEAR wa23-material.
        ENDIF.


      ENDIF.





      SHIFT wa23-ebelp LEFT DELETING LEADING '0'.
      wa23-ebelp_n = wa23-ebelp.


      SHIFT wa23-mfrpn LEFT DELETING LEADING '0'.

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*>>> GRADE NO - CHANGE 3 of 4 (PUT EKPO-BEDNR IN COLUMN)  ---  COPY FROM HERE
*>>> Paste after:  SHIFT wa23-mfrpn LEFT DELETING LEADING '0'.
*>>> and BEFORE:   APPEND wa23 TO it23 .
*>>> (after the SHIFT so leading zeros in BEDNR are kept as entered)
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      IF lv_grd_item23 EQ abap_true.                      "<<< NEW
        CLEAR wa23-mfrpn.                                 "<<< NEW
        wa23-mfrpn = ls_grd23-bednr.                      "<<< NEW  EKPO-BEDNR, CHAR 10
        lv_grd_cnt23 = lv_grd_cnt23 + 1.                  "<<< NEW
      ENDIF.                                              "<<< NEW
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*<<< GRADE NO - CHANGE 3 of 4 (PUT EKPO-BEDNR IN COLUMN)  ---  COPY TILL HERE
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

*  IF LOEKZ IS INITIAL .
      APPEND wa23 TO it23 .
      CLEAR wa23 .
*  ENDIF.
*  CLEAR : LOEKZ.

    ENDSELECT.

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*>>> GRADE NO - CHANGE 4 of 4 (COLUMN TITLE HD-MFRPN_TITLE)  ---  COPY FROM HERE
*>>> Paste right after the ENDSELECT. of the item loop (SELECT ... FROM ekpo)
*>>> Needs field MFRPN_TITLE (CHAR40) in structure ZMM_ST_EXTERNALPO.
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    IF lv_grd_cnt23 > 0 AND lv_grd_cnt23 EQ lv_itm_cnt23.              "<<< NEW
      hd23-mfrpn_title = 'GRADE NO'.                                  "<<< NEW
    ELSEIF lv_grd_cnt23 > 0.                                          "<<< NEW
*     Mixed PO: some items qualify, some do not
      hd23-mfrpn_title = 'Manufacturer Part No./ Code / GRADE NO'.    "<<< NEW
    ELSE.                                                             "<<< NEW
      hd23-mfrpn_title = 'Manufacturer Part No./ Code'.               "<<< NEW
    ENDIF.                                                            "<<< NEW
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*<<< GRADE NO - CHANGE 4 of 4 (COLUMN TITLE HD-MFRPN_TITLE)  ---  COPY TILL HERE
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    BREAK aalmansoub.
*SORT IT23  ASCENDING BY ebelp_N.


* Sort the table by the integer field
* Convert NUMC to internal format using CONVERSION_EXIT_ALPHA_INPUT
    LOOP AT it23 INTO wa23.
*  lv_numc = ls_row-your_numc_field.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = wa23-ebelp
        IMPORTING
          output = wa23-ebelp_N.
*  ls_row-your_numc_field = lv_alpha.
      MODIFY it23 FROM wa23.
    ENDLOOP.

    BREAK aalmansoub.
    SORT it23  ASCENDING BY ebelp_N.
*-------------------------------------------------------------------------
    hd23-Amount = Total23 .

*CALL FUNCTION 'ZSPELL_AMOUNT_EN'
*  EXPORTING
*    AMOUNT         = HD23-Amount
*    LANGUAGE       = SY-LANGU
* IMPORTING
*   RESULT         = HD23-WORDS
*          .
*
*    IF hd23-bukrs = '2300' OR hd23-bukrs = '2900'.
*      CALL FUNCTION 'ZSPELL_AMOUNT_EN_ALL_2300'   " EDIT 26.03.2019
*        EXPORTING
*          amount   = hd23-amount
*          currency = hd23-waers
**         iv_bukrs = hd23-bukrs
*        IMPORTING
*          result   = hd23-words.
*
*    ELSE. SHADY ALMURAISH

      CALL FUNCTION 'ZSPELL_AMOUNT_EN_ALL'   " EDIT 26.03.2019
        EXPORTING
          amount   = hd23-amount
          currency = hd23-waers
*         iv_bukrs = hd23-bukrs
        IMPORTING
          result   = hd23-words.

*    ENDIF.




    hd23-header =  'Purchase Order External'.


*data: excep type REF TO cx_root.
*data: v_str type string.



*----------------------------------------------------------------------------------
    BREAK malabsi.
*     -------------------------------
    BREAK aalmansoub.
*  To find Footer
    SELECT SINGLE werks INTO hd23-werks FROM ekpo  WHERE ebeln EQ hd23-ebeln AND ebelp EQ '00010'.
    SELECT SINGLE adrnr FROM t001w INTO ft7-adrnr WHERE werks EQ hd23-werks.  "" PLANT LEVEL
    SELECT SINGLE country region FROM adrc INTO (ft7-country, bland7) WHERE addrnumber EQ ft7-adrnr   .
*SELECT SINGLE COUNTRY FROM ADRC INTO FT-COUNTRY_EN  WHERE ADDRNUMBER EQ FT-ADRNR   .
    SELECT SINGLE landx50 FROM t005t INTO ft7-landx50_ar  WHERE land1 EQ ft7-country AND spras EQ 'AR'.
    SELECT SINGLE landx50 FROM t005t INTO ft7-landx50_en  WHERE land1 EQ ft7-country AND spras EQ 'EN'.
* ----------------------------
* To find Region
    SELECT SINGLE bezei FROM T005u INTO ft7-region_ar  WHERE land1 EQ ft7-country AND spras EQ 'AR' AND bland EQ bland7.
    SELECT SINGLE bezei FROM T005u INTO ft7-region_en  WHERE land1 EQ ft7-country AND spras EQ 'DE' AND bland EQ bland7.


*   Find Header data
    SELECT SINGLE adrnr FROM t001 INTO h7-addrnumber  WHERE bukrs EQ hd23-bukrs.
*H7-ADDRNUMBER = FT7-ADRNR.
    SELECT SINGLE name1 name2 sort1 FROM adrc INTO CORRESPONDING FIELDS OF h7  WHERE addrnumber EQ h7-addrnumber .
    CONCATENATE  ft7-region_en ft7-landx50_en   INTO ft7-landx50_en SEPARATED BY '-'.
    CONCATENATE  ft7-REGION_ar  ft7-LANDX50_ar  INTO ft7-landx50_ar SEPARATED BY '-'.
*CONCATENATE H-name2 FT-REGION_AR INTO HD-TITLE_AR SEPARATED BY ' - '.
*CONCATENATE H-name1 FT-REGION_EN INTO HD-TITLE_EN SEPARATED BY ' - '.
    CONCATENATE 'بيانات' h7-name2 INTO h7-title_AR SEPARATED BY ' '.
    SELECT SINGLE tel_number fax_number po_box FROM adrc INTO (ft7-tel_number , ft7-fax_number , ft7-po_box) WHERE addrnumber EQ ft7-adrnr .
    SELECT SINGLE uri_srch FROM adr12 INTO ft7-uri_addr WHERE addrnumber EQ ft7-adrnr AND uri_type EQ 'HPG' .
*  if HD7-BUKRS eq '1100' or HD7-BUKRS eq '1200' or HD7-BUKRS eq '1300' .
*    FT7-URI_ADDR = 'www.ycfms.com'.
*    ENDIF.    "hereeeeeeeee
    SELECT SINGLE smtp_addr FROM adr6 INTO ft7-smtp_addr WHERE addrnumber EQ ft7-adrnr .

*----------------------------------------------------------------------


    BREAK aalmansoub.
*if WA23-MFRPN is INITIAL.
*if ( ( doc_type = 'ZLPO' or doc_type = 'ZEPO' ) and  ( pg = 'P01' or Pg = 'P02' ) ).
*
*SELECT SINGLE EKPO~MATNR into hd23-material
*  from ekpo
*  where EBELN = HD23-EBELN
*  and EBELP = WA23-EBELP
*  AND EKPO~MTART = 'ZPCK'
*  AND EKPO~BUKRS = '1000'
*  AND EKPO~WERKS = '1010'.
**  AND EKPO~EKGRP = 'P01' and EKPO~EKGRP = 'P02'.
*
*clear WA23-MFRPN.
*WA23-MFRPN = hd23-material.
*clear hd23-material.
*endif.
*
*
*endif.
    BREAK aalmansoub.
*  SHIFT IT23-MFRPN LEFT DELETING LEADING '0'.

    TRY.
*  Data print_year TYPE char4 .
        print_year = sy-datum+0(4).
        BREAK aalmansoub.
*        IF hd23-bukrs = '1000' AND pg = 'P02'.
*
*          CALL FUNCTION 'ZFM_REPLACMENT_LOST'
*            EXPORTING
*              bukrs      = hd23-bukrs
*              vbeln      = hd23-ebeln
*              doc_type   = 'ZEPO' "HD23-LGORT
*              mod        = 'MM'
*              rep_name   = 'ZMM_F_EXTERNALPO_YCIC'
*              print_date = sy-datum
*              print_year = print_year
*              print_user = sy-uname
*            IMPORTING
*              version    = hd23-version.
**  TABLES
**    ZREPLACMENT_LOST       =
*
*          IF hd23-version <> 0 OR hd23-version = '' .
*            CONCATENATE  'Purchase Order External'  ' Duplicate Copy' hd23-version  INTO   hd23-header SEPARATED BY space.
*          ENDIF.
*
*        ELSEIF hd23-bukrs = '1000' AND pg = 'P03'.
*
*
*          CALL FUNCTION 'ZFM_REPLACMENT_LOST'
*            EXPORTING
*              bukrs      = hd23-bukrs
*              vbeln      = hd23-ebeln
*              doc_type   = 'ZEPO' "HD23-LGORT
*              mod        = 'MM'
*              rep_name   = 'ZMM_F_EXTERNALPO_YCIC_P03'
*              print_date = sy-datum
*              print_year = print_year
*              print_user = sy-uname
*            IMPORTING
*              version    = hd23-version.
**  TABLES
**    ZREPLACMENT_LOST       =
*
*          IF hd23-version <> 0 OR hd23-version = '' .
*            CONCATENATE  'Purchase Order External'  ' Duplicate Copy' hd23-version  INTO   hd23-header SEPARATED BY space.
*          ENDIF.
*
*        ELSEIF hd23-bukrs = '2400'.
*          CALL FUNCTION 'ZFM_REPLACMENT_LOST'
*            EXPORTING
*              bukrs      = hd23-bukrs
*              vbeln      = hd23-ebeln
*              doc_type   = 'ZEPO' "HD23-LGORT
*              mod        = 'MM'
*              rep_name   = 'ZMM_F_EXTERNALPO_2400'
*              print_date = sy-datum
*              print_year = print_year
*              print_user = sy-uname
*            IMPORTING
*              version    = hd23-version.
**  TABLES
**    ZREPLACMENT_LOST       =
*
*          IF hd23-version <> 0 OR hd23-version = '' .
*            CONCATENATE  'Purchase Order External'  ' Duplicate Copy' hd23-version  INTO   hd23-header SEPARATED BY space.
*          ENDIF.
*        ELSEIF hd23-bukrs = '2300' OR hd23-bukrs = '2900'.
*          CALL FUNCTION 'ZFM_REPLACMENT_LOST'
*            EXPORTING
*              bukrs      = hd23-bukrs
*              vbeln      = hd23-ebeln
*              doc_type   = 'ZEPO' "HD23-LGORT
*              mod        = 'MM'
*              rep_name   = 'ZMM_F_EXTERNALPO_2300'
*              print_date = sy-datum
*              print_year = print_year
*              print_user = sy-uname
*            IMPORTING
*              version    = hd23-version.
**  TABLES
**    ZREPLACMENT_LOST       =
*
*          IF hd23-version <> 0 OR hd23-version = '' .
*            CONCATENATE  'Purchase Order External'  ' Duplicate Copy' hd23-version  INTO   hd23-header SEPARATED BY space.
*          ENDIF.
**        ELSE.
*        UNIFIED EXTERNAL PO DONE BY SHADY ALMURAISH
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*>>> REMOVE "DUPLICATE COPY"  ---  COPY FROM HERE
*>>> Request: the word "Duplicate Copy" is not needed on the printout.
*>>> The header stays 'Purchase Order External' for every print.
*>>> ZFM_REPLACMENT_LOST below is kept, so print versions are still logged.
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*        IF hd23-version <> 0 OR hd23-version = '' .                                                                         "<<< OLD
*            CONCATENATE  'Purchase Order External'  ' Duplicate Copy' hd23-version  INTO   hd23-header SEPARATED BY space.  "<<< OLD
*          ENDIF.                                                                                                             "<<< OLD
          hd23-header = 'Purchase Order External'.                "<<< NEW
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*<<< REMOVE "DUPLICATE COPY"  ---  COPY TILL HERE
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
          CALL FUNCTION 'ZFM_REPLACMENT_LOST'
            EXPORTING
              bukrs      = hd23-bukrs
              vbeln      = hd23-ebeln
              doc_type   = 'ZEPO' "HD23-LGORT
              mod        = 'MM'
*             rep_name   = 'ZMM_F_EXTERNALPO' "SHADY ALMURISH
              rep_name   = 'ZMM_F_EXTERNALPO_TRYSH'
              print_date = sy-datum
              print_year = print_year
              print_user = sy-uname
            IMPORTING
              version    = hd23-version.
*  TABLES
*    ZREPLACMENT_LOST       =

          IF hd23-version <> 0 OR hd23-version = '' .
            " Eng / Shady Almuraish
*            CONCATENATE  'Purchase Order External'  ' Duplicate Copy' hd23-version  INTO   hd23-header SEPARATED BY space.
          ENDIF.

*        ENDIF.
      CATCH cx_root INTO excep.

    ENDTRY.



    IF excep IS NOT INITIAL.
      CALL METHOD excep->if_message~get_text
        RECEIVING
          result = v_str.

      "  CONCATENATE RESULT v_str INTO RESULT SEPARATED BY SPACE.
    ENDIF.







*********************************************
    fp_docparams-langu   = 'E'.
    fp_outputparams-dest = 'ZPDF'. "Output device
*             fp_outputparams-nodialog = '' . "ABAP_FALSE. "No user dialog
*             fp_outputparams-PREVIEW  = abap_true.
    "fp_outputparams-dest = 'ZPDF'. " z_pdest. "Printer name
    fp_outputparams-reqnew = abap_true. "New spool request
    fp_outputparams-reqimm = abap_true. "Print immediately

**********************************************
    CALL FUNCTION 'FP_JOB_OPEN'
      CHANGING
        ie_outputparams = fp_outputparams
      EXCEPTIONS
        cancel          = 1
        usage_error     = 2
        system_error    = 3
        internal_error  = 4
        OTHERS          = 5.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    " Added by Mohamed Safaa for adding total of Kwert and total amount 12/2/2020

*SELECT sum( PRCD_ELEMENTS~KWERT ) FROM EKKO JOIN prcd_elements ON ( EKKO~KNUMV EQ prcd_elements~KNUMV ) INTO HD23-TOTAL_KWERT
*  WHERE EKKO~EBELN eq doc_no AND ( PRCD_ELEMENTS~KSCHL NE 'PBXX' ) AND ( EKKO~BUKRS EQ '1100' OR EKKO~BUKRS EQ '1200' OR EKKO~BUKRS EQ '1300' ).

    DATA :text_name TYPE thead-tdname,
          lines     TYPE TABLE OF tline,
          lines_wa  LIKE tline,
          others    TYPE tline-tdline.


    " MOHAMED SAFAA , KHALED MABROUK , EDITING OTHERS VALUE
*SELECT SINGLE CLUSTD INTO CLUSTD FROM STXL WHERE TDID EQ 'F26' AND TDNAME EQ DOC_NO AND TDOBJECT EQ 'EKKO' AND TDSPRAS EQ 'A' .

    text_name = doc_no .

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        id       = 'F26'
        language = 'A'
        name     = text_name
        object   = 'EKKO'
      TABLES
        lines    = lines
      EXCEPTIONS
        OTHERS   = 8.
    IF sy-subrc EQ 0.
      READ TABLE lines INTO lines_wa INDEX 1 .
      others = lines_wa-tdline .
    ELSE .

      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          id       = 'F26'
          language = 'E'
          name     = text_name
          object   = 'EKKO'
        TABLES
          lines    = lines
        EXCEPTIONS
          OTHERS   = 8.

      IF sy-subrc EQ 0.
        READ TABLE lines INTO lines_wa INDEX 1 .
        others = lines_wa-tdline .
      ELSE .
        others = lines_wa-tdline .
      ENDIF.
    ENDIF.

    IF '.' CN others .
      CONCATENATE others '.00' INTO others.
    ENDIF.
    hd23-total_kwert = others .
    hd23-final_amount = hd23-amount + hd23-total_kwert .

*    IF hd23-bukrs = '2300' OR hd23-bukrs = '2900'.
*      CALL FUNCTION 'ZSPELL_AMOUNT_EN_ALL_2300'   " EDIT 26.03.2019
*        EXPORTING
*          amount   = hd23-final_amount
*          currency = hd23-waers
**         iv_bukrs = hd23-bukrs
*        IMPORTING
*          result   = hd23-final_words.
*
*      CALL FUNCTION 'ZSPELL_AMOUNT_EN_ALL_2300'   " EDIT 26.03.2019
*        EXPORTING
*          amount   = hd23-total_kwert
*          currency = hd23-waers
**         iv_bukrs = hd23-bukrs
*        IMPORTING
*          result   = hd23-kwert_words.
*    ELSE. SHADY ALMURAISH
      CALL FUNCTION 'ZSPELL_AMOUNT_EN_ALL'   " EDIT 26.03.2019
        EXPORTING
          amount   = hd23-final_amount
          currency = hd23-waers
*         iv_bukrs = hd23-bukrs
        IMPORTING
          result   = hd23-final_words.

      CALL FUNCTION 'ZSPELL_AMOUNT_EN_ALL'   " EDIT 26.03.2019
        EXPORTING
          amount   = hd23-total_kwert
          currency = hd23-waers
*         iv_bukrs = hd23-bukrs
        IMPORTING
          result   = hd23-kwert_words.

*    ENDIF.

*CALL FUNCTION 'ZSPELL_AMOUNT_EN_ALL'   " EDIT 26.03.2019
*  EXPORTING
*    amount         =  OTHERS
*    currency       =  HD23-waers
* IMPORTING
*   RESULT         =  HD23-KWERT_WORDS .


    " End of editing
    BREAK aalmansoub.
**    IF hd23-bukrs = '1000' AND pg = 'P02'.
**
**      CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
**        EXPORTING
**          i_name     = 'ZMM_F_EXTERNALPO_YCIC'
**        IMPORTING
**          e_funcname = fm_name.
**
***fp_docparams-langu = 'E' .
***fp_docparams-country = 'EG' .
**      CALL FUNCTION fm_name
**        EXPORTING
**          /1bcdwb/docparams = fp_docparams
**          hd                = hd23
**          cc                = hd23-bukrs
**          ft                = ft7
**          h                 = h7
***         OTHERS            = OTHERS
**          Table             = it23
*** IMPORTING
***         /1BCDWB/FORMOUTPUT       =
*** EXCEPTIONS
***         USAGE_ERROR       = 1
***         SYSTEM_ERROR      = 2
***         INTERNAL_ERROR    = 3
***         OTHERS            = 4
**        .
**      IF sy-subrc <> 0.
*** Implement suitable error handling here
**      ENDIF.
**    ELSEIF hd23-bukrs = '1000' AND pg = 'P03'.
**
**      CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
**        EXPORTING
**          i_name     = 'ZMM_F_EXTERNALPO_YCIC_P03'
**        IMPORTING
**          e_funcname = fm_name.
**
***fp_docparams-langu = 'E' .
***fp_docparams-country = 'EG' .
**      CALL FUNCTION fm_name
**        EXPORTING
**          /1bcdwb/docparams = fp_docparams
**          hd                = hd23
**          cc                = hd23-bukrs
**          ft                = ft7
**          h                 = h7
***         OTHERS            = OTHERS
**          Table             = it23
*** IMPORTING
***         /1BCDWB/FORMOUTPUT       =
*** EXCEPTIONS
***         USAGE_ERROR       = 1
***         SYSTEM_ERROR      = 2
***         INTERNAL_ERROR    = 3
***         OTHERS            = 4
**        .
**      IF sy-subrc <> 0.
*** Implement suitable error handling here
**      ENDIF.
**    ELSEIF hd23-bukrs = '2400'.
**
**      CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
**        EXPORTING
**          i_name     = 'ZMM_F_EXTERNALPO_2400'
**        IMPORTING
**          e_funcname = fm_name.
**
***fp_docparams-langu = 'E' .
***fp_docparams-country = 'EG' .
**      CALL FUNCTION fm_name
**        EXPORTING
**          /1bcdwb/docparams = fp_docparams
**          hd                = hd23
**          cc                = hd23-bukrs
**          ft                = ft7
**          h                 = h7
***         OTHERS            = OTHERS
**          Table             = it23
*** IMPORTING
***         /1BCDWB/FORMOUTPUT       =
*** EXCEPTIONS
***         USAGE_ERROR       = 1
***         SYSTEM_ERROR      = 2
***         INTERNAL_ERROR    = 3
***         OTHERS            = 4
**        .
**      IF sy-subrc <> 0.
*** Implement suitable error handling here
**      ENDIF.
**    ELSEIF hd23-bukrs = '2300' OR hd23-bukrs = '2900'.
**
**      CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
**        EXPORTING
**          i_name     = 'ZMM_F_EXTERNALPO_2300'
**        IMPORTING
**          e_funcname = fm_name.
**
***fp_docparams-langu = 'E' .
***fp_docparams-country = 'EG' .
**      CALL FUNCTION fm_name
**        EXPORTING
**          /1bcdwb/docparams = fp_docparams
**          hd                = hd23
**          cc                = hd23-bukrs
**          ft                = ft7
**          h                 = h7
***         OTHERS            = OTHERS
**          Table             = it23
*** IMPORTING
***         /1BCDWB/FORMOUTPUT       =
*** EXCEPTIONS
***         USAGE_ERROR       = 1
***         SYSTEM_ERROR      = 2
***         INTERNAL_ERROR    = 3
***         OTHERS            = 4
**        .
**      IF sy-subrc <> 0.
*** Implement suitable error handling here
**      ENDIF.

*    SHADY ALMURAISH
*    ELSE.
* Edited by shady almurish
      CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
        EXPORTING
          i_name     = 'ZMM_F_EXTERNALPO_TRYSH'
*         i_name     = 'ZMM_F_EXTERNALPO'
        IMPORTING
          e_funcname = fm_name.

*fp_docparams-langu = 'E' .
*fp_docparams-country = 'EG' .
      CALL FUNCTION fm_name
        EXPORTING
          /1bcdwb/docparams = fp_docparams
          hd                = hd23
          cc                = hd23-bukrs
          ft                = ft7
          h                 = h7
*         OTHERS            = OTHERS
          Table             = it23
* IMPORTING
*         /1BCDWB/FORMOUTPUT       =
* EXCEPTIONS
*         USAGE_ERROR       = 1
*         SYSTEM_ERROR      = 2
*         INTERNAL_ERROR    = 3
*         OTHERS            = 4
        .
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.

*    ENDIF. SHADY ALMURAISH

    CALL FUNCTION 'FP_JOB_CLOSE'
      EXCEPTIONS
        usage_error    = 1
        system_error   = 2
        internal_error = 3
        OTHERS         = 4.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

*  End of External PO .
**********************************************************************************************************************************

    " External po asset


    BREAK abaphsa03.
    BREAK aalmansoub.

* Extenal PO
