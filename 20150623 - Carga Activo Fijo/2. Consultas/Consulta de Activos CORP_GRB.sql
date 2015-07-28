SELECT FAV.ASSET_NUMBER             AS  ASSET_NUMBER,
       FAV.DESCRIPTION              AS  ASSET_DESCRIPTION,
       FAV.ATTRIBUTE_CATEGORY_CODE  AS  ASSET_CATEGORY,
       FBB.DATE_PLACED_IN_SERVICE   AS  ASSET_DATE_IN_SERVICE
  FROM FA_ADDITIONS_V           FAV,
       FA_BOOKS                 FA,
       FA_BOOKS_BOOK_CONTROLS_V FBB
 WHERE 1 = 1 
   AND FAV.ASSET_ID = FA.ASSET_ID
   AND FA.BOOK_TYPE_CODE = 'CORP GRB'
   AND NVL(FA.DISABLED_FLAG, 'N') = 'N'
   AND FA.TRANSACTION_HEADER_ID_OUT IS NULL
   AND FAV.ASSET_ID = FBB.ASSET_ID;
   
    
    