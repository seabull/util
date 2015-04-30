SELECT  
  TRAN(PEn.Physical_Name)         "Table Name",
  TRAN(PAt.Physical_Name)         "Column Name",
  TRAN(PEn.Definition)            "Entity Definition",
  TRAN(PAt.Definition)            "Attribute Definition",
  TRAN(PAt.Physical_Data_Type)    "Column Data Type",
  PAt.physical_order              "Physical Order"
  --TRAN(PAt.Owner@)        "Entity Name",
  --TRAN(PEn.owner_path)            "Model Name",
  --TRAN(PAt.Name)                  "Attribute Name",
  --TRAN(PAt.Null_Option_Type)      "Column Null Option",
  --CASE WHEN Keys.Key_Name            IS NULL THEN 'No' ELSE 'Yes' END "Column Is PK",
  --CASE WHEN PAt.Parent_Attribute_Ref IS NULL THEN 'No' ELSE 'Yes' END "Column Is FK",
  --PAt.attribute_order             "Logical Order",
  --PAt.column_order                "Column Order",
  --123                             "abc"
FROM    M0.Entity Pen
JOIN    M0.Attribute Pat ON PAt.owner@ = PEn.Id@
--LEFT JOIN
--(
--  SELECT LEn.Name Entity_Name,
--         KGM.Name Key_Name
--    FROM EM0.MV_Logical_Entity@ LEn
--  INNER JOIN EM0.MV_Logical_Key_Group@ LKG ON LEn.Id@ = LKG.Owner@
--  INNER JOIN M0.Key_Group_Member KGM ON LKG.Id@ = KGM.Owner@
--  WHERE LKG.Key_Group_Type = 'PK'
--) Keys on Keys.Entity_Name = TRAN(PAt.Owner@)and Keys.Key_Name = TRAN(PAt.Name)
WHERE   PAt.PARENT_ATTRIBUTE_REF is null
AND ISNULL(PEn.IS_LOGICAL_ONLY,'F') <> 'T'
AND ISNULL(PAT.IS_LOGICAL_ONLY,'F') <> 'T'
UNION
SELECT  
  TRAN(PAt.Child_Entity_Physical_Name@)   "Table Name",
  TRAN(PAt.CHILD_ATTRIBUTE_Physical_Name@)         "Column Name",
  TRAN(PAt.CHILD_ENTITY_DEFINITION@)      "Entity Definition",
  TRAN(PAt.CHILD_ATTRIBUTE_Definition@)   "Attribute Definition",
  TRAN(PAt.CHILD_ATTRIBUTE_Physical_Data_Type@) "Column Data Type",
  PAt.CHILD_ATTRIBUTE_physical_order@     "Physical Order"
  --TRAN(PAt.CHILD_ATTRIBUTE_Owner@) "Entity Name",
  --TRAN(PAt.PARENT_ENTITY_owner_path@)     "Model Name",
  --TRAN(PAt.CHILD_ATTRIBUTE_Name@)         "Attribute Name",
  --TRAN(PAt.CHILD_ATTRIBUTE_Null_Option_Type@)      "Column Null Option",
  --CASE WHEN Keys.Key_Name IS NULL THEN 'No' ELSE 'Yes' END "Column Is PK",
  --CASE WHEN PAt.CHILD_ATTRIBUTE_Parent_Attribute_Ref@ IS NULL THEN 'No' ELSE 'Yes' END "Column Is FK",
  --PAt.CHILD_ATTRIBUTE_attribute_order@    "Logical Order",
  --PAt.CHILD_ATTRIBUTE_column_order@       "Column Order",
  --PAt.CHILD_ENTITY_TYPE@          "abc"
FROM    EM0.MV_FOREIGN_KEY_ATTRIBUTE@ PAt
  --LEFT JOIN
  --(SELECT LEn.Name Entity_Name,
  --KGM.Name Key_Name
  --FROM    EM0.MV_Logical_Entity@ LEn
  --JOIN    EM0.MV_Logical_Key_Group@ LKG ON LEn.Id@ = LKG.Owner@
  --JOIN    M0.Key_Group_Member KGM ON LKG.Id@ = KGM.Owner@
  --WHERE   LKG.Key_Group_Type = 'PK'
  --) Keys  ON  Keys.Entity_Name = TRAN(PAt.CHILD_ATTRIBUTE_Owner@)
  --AND Keys.Key_Name = TRAN(PAt.CHILD_ATTRIBUTE_Name@)
WHERE  (PAt.CHILD_ATTRIBUTE_PHYSICAL_LEAD_ATTRIBUTE_REF@ IS NULL
OR      PAt.CHILD_ATTRIBUTE_PHYSICAL_LEAD_ATTRIBUTE_REF@ = PAt.CHILD_ATTRIBUTE_Id@ )
AND   ISNULL(PAt.CHILD_ATTRIBUTE_IS_LOGICAL_ONLY@, 'F')  <> 'T'
AND     PAt.CHILD_ENTITY_TYPE@ = '1075838979'
/
