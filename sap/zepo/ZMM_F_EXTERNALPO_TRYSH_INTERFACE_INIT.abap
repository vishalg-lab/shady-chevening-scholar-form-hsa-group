*----------------------------------------------------------------------*
* SFP Interface of ZMM_F_EXTERNALPO_TRYSH  ->  Code Initialization
* Logo selection:
*   XSTRING   -> layout field GRAPHIC   (company logo, SE78 name = company code)
*   XSTRING1  -> layout field GRAPHIC1  (ISO logo,     SE78 name = 'ISO' + company code)
*   XSTRING2  -> 'ISO 1000'
*----------------------------------------------------------------------*

 string = 'image/bmp'.

 data: lv_logoname TYPE TDOBNAME ,lv_ISOlogoname TYPE TDOBNAME.

*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*>>> LOGO FIX - CHANGE 1 of 2 (CLEAR OLD LOGOS)  ---  COPY FROM HERE
*>>> Paste after the DATA statement above.
*>>> Global data keeps its value between calls in the same session. When a
*>>> logo is not found in SE78 the method raises NOT_FOUND and does NOT
*>>> overwrite XSTRING, so the logo of the previous PO (e.g. Hodeidah) is
*>>> printed on the next PO (e.g. Taiz). Clearing first prevents this.
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
 CLEAR: xstring, xstring1, xstring2,                     "<<< NEW
        lv_logoname, lv_ISOlogoname.                     "<<< NEW
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*<<< LOGO FIX - CHANGE 1 of 2 (CLEAR OLD LOGOS)  ---  COPY TILL HERE
*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

 *or CC EQ 1200 or CC Eq 1300
 lv_logoname = HD-BUKRS.

 CALL METHOD cl_ssf_xsf_utilities=>get_bds_graphic_as_bmp
 EXPORTING
 p_object = 'GRAPHICS'
 p_name = lv_logoname
 p_id = 'BMAP'
 p_btype = 'BCOL'
 RECEIVING
 p_bmp = xstring
 EXCEPTIONS
 not_found = 1
 internal_error = 2
 OTHERS = 3.

 if CC eq 1100 . " ADAN
 lv_logoname = '1100'.
 lv_ISOlogoname = 'ISO1100'.

 ELSEIF CC EQ 1400. " NATCO
 lv_logoname = '1400'.
 lv_ISOlogoname = 'ISO1400'.
 ELSEIF CC EQ 1500. " HASCO
 lv_logoname = '1500'.
 lv_ISOlogoname = 'ISO1500'.
 ELSEIF CC EQ 1900. " HASCO
 lv_logoname = '1900'.
 lv_ISOlogoname = 'ISO1900'.
 ELSEIF CC EQ 3300. " HASCO
 lv_logoname = '3300'.
 lv_ISOlogoname = 'ISO3300'.
 ELSEIF CC EQ 3100. " HASCO
 lv_logoname = '3100'.
 lv_ISOlogoname = 'ISO3100'.
 ELSEIF CC EQ 1200. " HASCO
 lv_logoname = '1200'.
 lv_ISOlogoname = 'ISO1200'.
*>>> LOGO FIX - CHANGE 2 of 2 (1300 WAS WRITTEN AS 1200)  ---  COPY FROM HERE
 ELSEIF CC EQ 1300.                                      "<<< CHANGED (was: CC EQ 1200)
*<<< LOGO FIX - CHANGE 2 of 2 (1300 WAS WRITTEN AS 1200)  ---  COPY TILL HERE
 lv_logoname = '1300'.
 lv_ISOlogoname = 'ISO1300'.
 ELSEIF CC EQ 2400. " البان تعز
 lv_logoname = '2400'.
 lv_ISOlogoname = 'ISO2400'.
 ELSEIF CC EQ 5000. " البان الحديدة
 lv_logoname = '5000'.
 lv_ISOlogoname = 'ISO5000'.
 ENDIF.

 *Break ABAPCON01.

 CALL METHOD cl_ssf_xsf_utilities=>get_bds_graphic_as_bmp
 EXPORTING
 p_object = 'GRAPHICS'
 p_name = lv_ISOlogoname
 p_id = 'BMAP'
 p_btype = 'BCOL'
 RECEIVING
 p_bmp = xstring1
 EXCEPTIONS
 not_found = 1
 internal_error = 2
 OTHERS = 3.

 CALL METHOD cl_ssf_xsf_utilities=>get_bds_graphic_as_bmp
 EXPORTING
 p_object = 'GRAPHICS'
 p_name = 'ISO 1000'
 p_id = 'BMAP' "'JPEG'
 p_btype = 'BCOL' "'COLO'
 RECEIVING
 p_bmp = xstring2
 EXCEPTIONS
 not_found = 1
 internal_error = 2
 OTHERS = 3.
