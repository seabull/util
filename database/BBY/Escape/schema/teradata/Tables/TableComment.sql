COMMENT ON DEVBBYMEADHOCDB.ESC_TACS  IS 'The account receivable detail table contains all detailed account receivable information associated with specific account-commission id combinations' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TARD   IS 'Adjustment Account Receivable Detail' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TARS   IS 'Account Receivable Status Type table' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TASC   IS 'account commission table acts as a transition table solving the many-to-many relationship between customer accounts and commission models. The specific combination of these two entities is used to schedule the posting of account receivable information.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TATA   IS 'Account Receivable Adjustment Type' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TBMD   IS 'bounty model table defines the commission models that can be used to calculate bounty account receivables for selling a providers subscription service at BBY. Individual bounty models can be used by several plans.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCAC   IS 'customer account table holds all customer accounts setup in the ESC system.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCAI   IS 'account line item table acts as a transition table solving the many-to-many relationship between customer accounts and transaction line items.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCAT   IS 'account receivable type table contains information pertaining to the type of information that an AR detail represents.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCMD   IS 'commission model table defines the commission models that can be used to calculate the appropriate account receivables for selling a providers subscription service at Best Buy. Individual commission models can be used by several plans.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCPT   IS 'chargeback period type table is a lookup table for describing each of the chargeback period types. Examples of period types are Days, Weeks, Months, Quarters and Years.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCSC   IS 'Schedule table is used for assigning a future date for processing customer accounts to determine account receivable revenue. The table is used by both the scheduling batch process (schedules items for future posting) and the posting batch process' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCSI   IS 'Account Secondary information' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCTP   IS 'commission model type table is a lookup table for describing each of the commission model types.  Currently, the only two commission model types are bounties and residuals.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TDVP   IS 'Default Vendor Plan table' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TEGT   IS 'Sales Integration table' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TFAT   IS 'File Activity type describing the type of communications being submitted to vendors. These are communications related to subscription service plans. Activity types include Cancellation,Activation,Activation Intent,Cancellation Intent, Payment, and Charge' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TKPG   IS 'SKU package group table identifies a group of SKU packages.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TLIA   IS 'line item attribute table acts as a transition table solving the many-to-many relationship between transaction line items and line item attributes.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TLNI   IS 'line item table represents specific line items on a transaction that are associated with subscription service sales (SKUs). This is a surrogate definition of a line item, not necessarily the physical line item on a transaction.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPAD   IS 'Inbound CSV File setup table' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPAK   IS 'Plan SKU table acts as a transition table solving the many-to-many relationship between subscription plans and activation SKUs.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPKG   IS 'SKU package table identifies an assembly of  SKUs for related items that can be sold together as a package.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPKP   IS 'primary SKU table identifies primary SKUs. For the ESC system, these are hardware SKUs (cell phone, DBS receiver, set top box).' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPKT   IS '' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPLC   IS 'plan commission table acts as a transition table solving the many-to-many relationship between subscription plans and commission models.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TPLN   IS 'subscription plan table defines the different plans that service providers offer. Plans are specific to a particular vendor such that AT&Ts 600 minute cellular plan is different from Sprints 600 minute cellular plan.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TRMD   IS 'residual model table defines the commission models that can be used to calculate residual account receivables for selling a providers subscription service at Best Buy.  Individual residual models can be used by several plans.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TSKP   IS 'secondary SKU table identifies Secondary SKUs. For the ESC system, these are subscription activation SKUs.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TSLT   IS 'Transaction Header table identifies transactions that contain subscription service items.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TVAF   IS 'vendor activity file table defines each of the vendor feeds received from various vendors.  Vendor feeds can be either payments or notifications of cancellation and/or activation.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TVNI   IS 'vendor information table provides additional vendor information that is not located within the main Best Buy vendor table.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TVPF   IS 'vendor payment table defines those vendor activity files that are of the payment variety.  Payment files indicate the check or wire transfer number of the transaction as well as header information pertaining to the vendor payment.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TVPR   IS 'Each vendor has more than one conversion possibilities.  For each file profile type, and activity, a different conversion will occur.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TVPT   IS 'This is middle table to create a many to many relationship for Vendor Attribute Types and Vendor Attribute Profiles.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_CUSTCST   IS 'This table contains the unique identifier of a customer along with customer name,address and telephone information.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TCMH   IS 'Communication history table' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TSTD   IS 'The transaction detail table represents specific line items on a transaction that are associated with subscription service sales.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TDPT   IS 'This table holds the Commission Department information such as department type, department name, department description and department active flag.' 
;
COMMENT ON DEVBBYMEADHOCDB.ESC_TDPM   IS 'This table defines a mapping between a plan, the plans commission model, and the commission departments in which it can be sold, to get the posting SKU.' 
;
