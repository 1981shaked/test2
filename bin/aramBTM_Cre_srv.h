/******************************************************************************
*                                                                             *
* Name    : aramBTM_Cre_srv.h                                                 *
*           ---------------------                                             *
*                                                                             *
* Purpose : Create a new service in order to create adjustments / charges     *
*           according to the BTM structure and update the EQP_CHG_INFO        *
*           respectively.                                                     *
*                                                                             *
* Programmer          : Limor Torres.                                         *
* Supervisor          : Efrat Buchnick.                                       *
* Date                : 22/02/2006                                            *
*                                                                             *
*-----------------------------------------------------------------------------*
* Maintenance Log                                                             *
*-----------------------------------------------------------------------------*
* Change #            : #1                                                    *
* CR#/ TT/ SEMR/      : DEF#29737 task 39854                                  *
* Programmer          : Pradeep Mukkamala                                     *
* Supervisor          : Srikanth Pulipaka                                     *
* Change Date         : 07 Aug 2006                                           *
* Cause of Change     : Def#29737                                             *
* Change description  : Added the constant DOUBLE_100 for double 100.0        *
*                       to type cast the amount when passing to the memo func *
*-----------------------------------------------------------------------------*
* Change #            : #2                                                    *
* CR#/ TT/ SEMR/      : 41200                                                 *
* Version             : 9.4                                                   *
* Programmer          : Abhishek Agarwal                                      *
* Supervisor          : Abhishek Agarwal                                      *
* Change Date         : 12-MAR-2007                                           *
* Cause of Change     : Define New Constants, Add new fields to the INITIALIZE*
*                     : Macro for Adjustment Structure, and pass SOURCE-APPL-CODE
*                     : as an New Argument to GetAdjSeqNo.                    *
*-----------------------------------------------------------------------------*
* Change #            : #3
* CR#/ TT/ SEMR/      : 42169
* Version             : 9.6
* Programmer          : Avnish Garg
* Supervisor          : Prashant Rajagopal
* Change Date         : 10-September-2007
* Cause of Change     : Changes for the kintana 42169 - Tax Normalization Phase - II
* Change description  : Changes for the kintana 42169 - Tax Normalization Phase - II
*-----------------------------------------------------------------------------*
* Change #            : #4
* CR#/ TT/ SEMR/      : 90458 
* Version             : 11020 
* Programmer          : Rasika Birajdar  
* Supervisor          : Vivek Tuteja 
* Change Date         : 12-Nov-2010 
* Cause of Change     : TLG AR will send the QPASS Charges and Adjustments in 
*                       the QPASS file for TITAN customers to TITAN Invoicing
*                       and TITAN AR respectively.
*-----------------------------------------------------------------------------*
******************************************************************************/

#ifndef  _ARAM_BTMCREATE_H
#define  _ARAM_BTMCREATE_H


/* System */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

/* Domains */

#include <funcsts.h>
#include <fullpathfn.h>
#include <datetime.h>
#include <yesnoind.h>
#include <prodtp.h>
#include <blseqno.h>
#include <eqpchgqty.h>
#include <taxbufsz_c.h>

/* Internals */
#include <ardebugflag.h>
#include <dl_sts.h>
#include <dlcontext.h>
#include <dlstrtrx.h>
#include <dlendtrx.h>
#include <dlroltrx.h>
#include <dlinit.h>
#include <errlibg.h>
#include <argn_msg.h>
#include <arPub_macros.h>
#include <ar_GnErrorHandler.h>
#include <gncontrol.h>
#include <xarcontext.h>
#include <pcs_titan_ar_api_c32.h> /* Change #4 */
#include <pcs_titan_bl_api_c32.h> /* Change #4 */
#include <rowid.h>         /* Change #4 */
#include <aractrsncd.h>    /* Change #4 */
#include <decddscext.h>    /* Change #4 */
#include <t_tncmpt.h>

/* structures */
#include <t_ban_k.h>
#include <t_ban.h>
#include <t_bancol.h>
#include <t_faninfo_k.h>
#include <t_faninfo.h>
#include <t_slbenroll.h>
#include <pgnobjattrbuff.h>
#include <cmasbli_in.h>
#include <cmasbli_out.h>
#include <t_chg_k.h>
#include <t_adj_k.h>
#include <t_chg.h>
#include <t_adj.h>
#include <aramAdj.h>
#include <pcsactvprm.h>
#include <t_memo.h>
#include <dllockprm.h>
#include <blbnccrgprm.h>
#include <t_arplcy_k.h>
#include <t_arplcy.h>
#include <bltxstruct.h>
#include <t_featur.h>
#include <t_chginf_k.h>
#include <t_chginf.h>

/* BTM structurs */
#include <arbtmerr.h>
#include <arbtmrec.h>
#include <arbtmdtl.h>
#include <arbtmhdr.h>
#include <t_eqpchg.h>

/* --------- */
/* Constants */
/* --------- */

#include <arbanbf_c.h>

static const char PROGRAM_NAME[]      = "aramBTM_Cre_srv";
static const char TAX_RSN[]           = "TAX";
static const char SHIP_RSN[]          = "SHIP";
static const char TEND_RSN[]          = "TEND";
static const char BTM_RSN[]           = "BTMEQP";
static const char CHARGE_ACT[]        = "CHG";
static const char ADJUSTMENT_ACT[]    = "ADJ";
static const char SLB_EQP_LIABILITY[] = "SLB Equipment Liability";
static const char CORP[]              = "Corporate";
static const char SUBSCRIBER_DUMMY[]  = "          ";
static const char SUB_TAX[]           = "SUBTAX";
static const char SUB_SHIP[]          = "SUBSHP";

#define ZERO_AMT              0
#define ONE_QTY               1
#define THREE_QTY             3
#define SLB_EQP_LIABILITY_SZ 38
#define CORP_SZ               9
#define FTRCD_SZ              6
/* Start Change #1  */
#define DOUBLE_100            100.0
/* End Change #1 */

/* Start Change #2  */
#define CH_SPACE              ' '
#define CH_NULL               '\0'
/* End Change #2 */

/* Start Change #4  */
short g_arApiBufIndx=0;
int g_invApiBufIndx=0;
#define IMD_CH "IC"
#define PED_CHG "PC"
#define PED_ADJ "PA"
#define IMD_ADJ "IA"
#define REV_CHG "RC"
#define REV_ADJ "RA"
#define CRE_CRD "CC"
#define CRE_CHG "CD"
#define COMPASS 'C'
/* End Change #4 */


typedef struct temp_btm
{
        SUBNO_C_D(sub_ctn);
        AMTLRG_C_D(sub_total_chg);
        AMTLRG_C_D(sub_total_adj);
        YESNOIND_C_D(sub_complete);

} temp_btm_rec;


#define CLEANSTRUCT(clrStr) (memset(&(clrStr), 0, sizeof(clrStr)))

/* Initialize structurs  */
#define INITIALIZE_OBJ_ATTR_BUFF_C( objAttrBuff ) \
                            { \
                                INITIALIZE_BUFSIZE_C(objAttrBuff.row_count); \
                                INITIALIZE_CHOBJECTID_C(objAttrBuff.obj_id); \
                                INITIALIZE_CHOBJTYPE_C(objAttrBuff.obj_type); \
                                INITIALIZE_CHOBJNAME_C(objAttrBuff.obj_name); \
                                INITIALIZE_CHOBJEXTID_C(objAttrBuff.obj_external_id); \
                                INITIALIZE_CHOBJDESC_C(objAttrBuff.obj_desc); \
                                { int i; \
                                for(i=0;i<=99;i++)\
                                {\
                                   TB_INITIALIZE_CH_OBJECT_ATTRIBUTES_1V_C( objAttrBuff.ch_obj_attr_1v[i] ); \
                        	}}\
                            }

#define INITIALIZE_PCSACTVPRM( actvPrm ) \
			    { \
                                INITIALIZE_ACTCD_C(actvPrm.act_code); \
                                INITIALIZE_STSCHGRSNCD_C(actvPrm.act_reason); \
                                INITIALIZE_SUBNO_C(actvPrm.memo_ctn); \
                                INITIALIZE_PRODTP_C(actvPrm.memo_product_type); \
                                INITIALIZE_MEMTXT_C(actvPrm.user_text); \
                                INITIALIZE_SRCAPPLCD_C(actvPrm.memo_source); \
                                INITIALIZE_BUFSIZE_C(actvPrm.param_count); \
                                INITIALIZE_MMPARAM_C(actvPrm.p1); \
                                INITIALIZE_MMPARAM_C(actvPrm.p2); \
                                INITIALIZE_MMPARAM_C(actvPrm.p3); \
                                INITIALIZE_MMPARAM_C(actvPrm.p4); \
                                INITIALIZE_MMPARAM_C(actvPrm.p5); \
                                INITIALIZE_MMPARAM_C(actvPrm.p6); \
                                INITIALIZE_MMPARAM_C(actvPrm.p7); \
                                INITIALIZE_MMPARAM_C(actvPrm.p8); \
                                INITIALIZE_MMPARAM_C(actvPrm.p9); \
                                INITIALIZE_MMPARAM_C(actvPrm.p10); \
                                INITIALIZE_AMTREG_C(actvPrm.memo_amt); \
                                INITIALIZE_RMSACTVCD_C(actvPrm.rms_act_code); \
                                INITIALIZE_MEMOPRM_C(actvPrm.memo_parm); \
                                INITIALIZE_STSCHGRSNCD_C(actvPrm.sts_sub_rsn_code); \
                                INITIALIZE_MEMOUID_C(actvPrm.client_user_id); \
                                INITIALIZE_MEMOUNAME_C(actvPrm.client_user_name); \
                             } 
/***************************************************************************
 *
 * aramBTM_Cre_srv
 *
 *
 * Purpose     : Handle and control the BTM structure
 *
 * Description : 1. initialize the program
 *               2. Handle BTM struct
 *                  1. Lock the BAN on the BTM structure
 *                  2. Create Header Adj/Chg
 *                  3. Create Deatil Adj/Chg
 *
 * Parameters  : arbtmrec.h      
 *
 * Return Value: status - FAILURE or SUCCESS
 *
 ***************************************************************************/

FUNCSTS_C_T aramBTM_Cre_srv( xarcontext_t * xarcontextRec , arbtmrec_t * ip_arbtmRec );




/*               LOCAL FUNCTIONS                                          */

/***************************************************************************
 *
 * InitProgram
 *
 * Purpose     : Initialize program's activities.
 *
 * Description : - Get the AR debug flag from the environment
 *               - Display starting message
 *               - Initialize variables
 *               - Get the environment variables
 *
 *
 * Parameters  : xarcontext_t * xarcontextRec
 *
 * Return Value: FAILURE or SUCCESS
 *
 ***************************************************************************/

static FUNCSTS_C_T InitProgram( xarcontext_t * xarcontextRec );



/***************************************************************************
 *
 * InitVariables
 *
 * Purpose     : Initialize program's variables.
 *
 * Description : - Initialize the DB connect indicator
 *               - Initialize the DL context record
 *               - Get the market code from the environment
 *               - Get the run date form the environment
 *               - Initialize program's static globals
 *
 * Parameters  : xarcontext_t * xarcontextRec
 *
 * Return Value: SUCCESS
 ***************************************************************************/
static FUNCSTS_C_T InitVariables( xarcontext_t * xarcontextRec );




/***************************************************************************
 *
 * CreateHeader
 *
 * Purpose     : Create the BTM header charges / adjustments 
 *
 * Description : Create Header adjustments / Charges :                           
 *                  For each header amount- tot_tax, tot_ship_chg, other_amt :   
 *	              If amount  < 0                                               
 * 		                1. Create Chg. memo                                
 * 		                2. Create Charge                                   
 * 		                3. Populate EQP_CHG_INFO                           
 * 	              Else If amount > 0                                           
 * 		                1. Create adj. memo                                
 * 		                2. Create Adjustment                               
 * 		                3. Populate EQP_CHG_INFO                           
 *                                                                                  
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec
 *               2. arbtmrec_t
 *
 * Return Value: FAILURE or SUCCESS
 *
 ***************************************************************************/
static FUNCSTS_C_T CreateHeader( xarcontext_t * xarcontextRec , arbtmrec_t * ip_btmRec );



/***************************************************************************
 *
 * CreTaxAmt
 *
 * Purpose     : Create TAX charges / adjustments 
 *
 * Description : Create TAX adjustments / Charges :  
 *	              If TAX amount  > 0                                               
 * 		                1. Create Chg. memo                                
 * 		                2. Create Charge                                   
 * 		                3. Populate EQP_CHG_INFO                           
 * 	              Else If TAX amount < 0                                           
 * 		                1. Create adj. memo                                
 * 		                2. Create Adjustment                               
 * 		                3. Populate EQP_CHG_INFO                              
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec , 
 *               2. arbtmrec_t
 *
 * Return Value: FAILURE or SUCCESS
 *
 ***************************************************************************/

static FUNCSTS_C_T CreTaxAmt( xarcontext_t * xarcontextRec , arbtmrec_t * ip_btmRec );



/***************************************************************************
 *
 * CreShipAmt
 *
 * Purpose     : Create Shipping charges / adjustments 
 *
 * Description : Create Shipping adjustments / Charges :  
 *	              If Shipping amount  > 0                                               
 * 		                1. Create Chg. memo                                
 * 		                2. Create Charge                                   
 * 		                3. Populate EQP_CHG_INFO                           
 * 	              Else If Shipping amount < 0                                           
 * 		                1. Create adj. memo                                
 * 		                2. Create Adjustment                               
 * 		                3. Populate EQP_CHG_INFO                              
 *                                                                                  
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec 
 *               2. arbtmrec_t
 *
 * Return Value: FAILURE or SUCCESS
 *
 ***************************************************************************/

static FUNCSTS_C_T CreShipAmt( xarcontext_t * xarcontextRec , arbtmrec_t * ip_btmRec );



/***************************************************************************
 *
 * CreTendAmt
 *
 * Purpose     : Create Tendered charges / adjustments 
 *
 * Description : Create Tendered adjustments / Charges :  
 *	              If Tendered amount  > 0                                               
 * 		                1. Create Chg. memo                                
 * 		                2. Create Charge                                   
 * 		                3. Populate EQP_CHG_INFO                           
 * 	              Else If Tendered amount < 0                                           
 * 		                1. Create adj. memo                                
 * 		                2. Create Adjustment                               
 * 		                3. Populate EQP_CHG_INFO                              
 *                                                                                  
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec
 *               2. arbtmrec_t
 *
 * Return Value: FAILURE or SUCCESS
 *
 ***************************************************************************/

static FUNCSTS_C_T CreTendAmt( xarcontext_t * xarcontextRec , arbtmrec_t * ip_btmRec );


/***************************************************************************
 *
 * CreSubTaxShip
 *
 * Purpose     : Create Subscriber level taxes and shiping charges/adj
 *
 * Description : Create Subscriber level taxes and shiping charges/adj
 *                    If  amount  > 0
 *                              1. Create Chg. memo
 *                              2. Create Charge
 *                              3. Populate EQP_CHG_INFO
 *                    Else If amount < 0
 *                              1. Create adj. memo
 *                              2. Create Adjustment
 *                              3. Populate EQP_CHG_INFO
 *
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec
 *               2. arbtmrec_t
 *
 * Return Value: FAILURE or SUCCESS
 *
 ***************************************************************************/

static FUNCSTS_C_T CreSubTaxShip( xarcontext_t * xarcontextRec , arbtmrec_t * ip_btmRec );




/***************************************************************************
 *
 * CreateDeatil
 *
 * Purpose     : Create the BTM detail charges / adjustments 
 *
 * Description : Create Detail adjustments / Charges :                        
 *                Loop btm_struct->rowcount times:                                
 *                1. If btm_struct->detail_rec[i]->ctn !=null                    
 *		        1. Check SLB                                                
 *		        2. Get product_type                                         
 *	                3. Lock BAN                                                    
 *                3. If btm_struct->detail_rec->item_total < 0                   
 *                      1. Create Adj. memo.                                      
 *	                2. Create Adjustment.                                     
 *                      3. Populate EQP_CHG_INFO                                  
 * 		     Else If btm_struct->detail_rec->item_total >= 0             
 *                      1. Create Chg. memo.                                      
 *	                2. Create Charge.                                         
 *                      3. Populate EQP_CHG_INFO                              
 *                                                                                  
 *
 * Parameters  :  xarcontext_t * xarcontextRec
 *                arbtmrec_t
 *
 * Return Value: FAILURE or SUCCESS
 *
 ***************************************************************************/
static FUNCSTS_C_T CreateDeatil( xarcontext_t * xarcontextRec , arbtmrec_t * ip_btmRec );



/***************************************************************************
 *
 * CreDetAmt
 *
 * Purpose     : Create Detail records charges / adjustments 
 *
 * Description : Create detail records adjustments / Charges :  
 *	              If item total amount  >= 0                                               
 * 		                1. Create Chg. memo                                
 * 		                2. Create Charge                                   
 * 		                3. Populate EQP_CHG_INFO                           
 * 	              Else If item total amount < 0                                           
 * 		                1. Create adj. memo                                
 * 		                2. Create Adjustment                               
 * 		                3. Populate EQP_CHG_INFO                              
 *                                                                                  
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec 
 *               2. arbtmrec_t * ip_btmRec 
 *               3. int i_indx 
 *
 * Return Value: FAILURE or SUCCESS
 *
 ***************************************************************************/

static FUNCSTS_C_T CreDetAmt( xarcontext_t * xarcontextRec , 
                              arbtmrec_t * ip_btmRec , 
                              int i_indx );
/***************************************************************************
 *
 * CreSumChgAdj
 *
 * Purpose     : Create Detail records charges / adjustments
 *
 * Description : Create detail records adjustments / Charges :
 *                    If item total amount  >= 0
 *                              1. Create Chg. memo
 *                              2. Create Charge
 *                    Else If item total amount < 0
 *                              1. Create adj. memo
 *                              2. Create Adjustment
 *               
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec
 *               2. arbtmrec_t * ip_btmRec
 *               3. int i_indx
 *
 * Return Value: FAILURE or SUCCESS
 *
 ***************************************************************************/

static FUNCSTS_C_T CreSumChgAdj( xarcontext_t * xarcontextRec , arbtmrec_t * ip_btmRec , int i_indx );



/***************************************************************************
 *
 * CheckSLB
 *
 * Purpose     : Check whether the NBI subscriber has a target BAN.
 *
 * Description : - Initialize all SLB variables
 *		 - Call dar_gb_slb_target_by_source
 *               - Check returned status 
 *               - Call dar_gt_ban for the target BAN
 *               - Check returned status 
 *               - Call arGtFan for the target BAN
 *               - Check returned status 
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec
 *               2. BAN_C_D(i_sourceBAN)
 *               3. SUBNO_C_D(i_sourceSUB)
 *
 * Return Value: The program's exit status.
 *
 ***************************************************************************/
static FUNCSTS_C_T CheckSLB( xarcontext_t * xarcontextRec , 
                             BAN_C_D(i_sourceBAN) , 
                             SUBNO_C_D(i_sourceSUB) );



/***************************************************************************
 *
 * LockBAN
 *
 * Purpose     : Lock the BAN. 
 *
 * Description : - Populate fields
 *		 - Call "dar_cr_eqp_chg_info"
 *               - Check returned status 
 *
 * Parameters  :  xarcontext_t * xarcontextRec
 *                BAN_C_D(i_banLk)
 *               
 *
 * Return Value: The program's exit status.
 *
 ***************************************************************************/
static FUNCSTS_C_T LockBAN( xarcontext_t * xarcontextRec , BAN_C_D(i_banLk) );



/***************************************************************************
 *
 * GetProductType
 *
 * Purpose     : Get the product type of a subscriber.
 *
 * Description : - Populate fields
 *		 - Call "dcs_gt_product_by_subno" 
 *               - Check returned status 
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec
 *               2. BAN_C_D(i_Ban)
 *               3. SUBNO_C_D(i_Sub)
 *
 * Return Value: The program's exit status.
 *
 ***************************************************************************/
static FUNCSTS_C_T GetProductType( xarcontext_t * xarcontextRec , 
                                   BAN_C_D(i_Ban) , 
                                   SUBNO_C_D(i_Sub) );



/***************************************************************************
 *
 * CreateEqpChgInfo
 *
 * Purpose     : Create a new entry for EQP_CHARGE_INFO table.
 *
 * Description : - Populate fields
 *		 - Call "dar_cr_eqp_chg_info"
 *               - Check returned status 
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec
 *               2. t_eqpchg_t
 *               3. arbtmrec_t
 *
 * Return Value: The program's exit status.
 *
 ***************************************************************************/
static FUNCSTS_C_T CreateEqpChgInfo( xarcontext_t * xarcontextRec , 
                                     t_eqpchg_t  * ip_eqpRec , 
                                     arbtmrec_t * ip_btmRec );



/***************************************************************************
 *
 * PopEqpChgInfo
 *
 * Purpose     : Populate parameters for EQP_CHARGE_INFO table.
 *
 * Description : - Populate fields
 *		 - Get actv-bill-seq-no for immediate charge
 *               - Get ent_seq_no from charge /adjustment record 
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec ,
 *               2. t_eqpchg_t
 *               3. arbtmrec_t
 *
 * Return Value: The program's exit status.
 *
 ***************************************************************************/
static FUNCSTS_C_T PopEqpChgInfo( xarcontext_t * xarcontextRec , 
                                  t_eqpchg_t * ip_eqpRec , 
                                  arbtmrec_t * ip_btmRec );



/***************************************************************************
 *
 * GetBillSeqNo
 *
 * Purpose     : Populate the actv_bill_seq_no in case of immediate charge.
 *
 * Description : - Populate fields
 *		 - Call blcm_asbli
 *               - Check returned status 
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec ,
 *               2. BLSEQNO_C_D(* ip_BillSeqNo) 
 *               3. BAN_C_D(i_Ban)
 *
 * Return Value: The program's exit status.
 *
 ***************************************************************************/
static FUNCSTS_C_T GetBillSeqNo( xarcontext_t * xarcontextRec , 
                                 BLSEQNO_C_D(* ip_BillSeqNo) , 
                                 BAN_C_D(i_Ban) );



/***************************************************************************
 *
 * GetAdjSeqNo
 *
 * Purpose     : Get the ent_seq_no in case of adjustment.
 *
 * Description : - Populate fields
 *		 - Call dar_gt_last_adj_ent_seq
 *               - Check returned status 
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec , 
 *               2. CHGSEQNO_C_D(* ip_ChgSeqNo) 
 *               3. BAN_C_D(i_Ban)
 *               4. SRCAPPLCD_C_D (i_SrcApplCd)
 *
 * Return Value: The program's exit status.
 *
 ***************************************************************************/
static FUNCSTS_C_T GetAdjSeqNo( xarcontext_t * xarcontextRec , 
                                CHGSEQNO_C_D(*ip_ChgSeqNo) , 
                                BAN_C_D(i_Ban),
                                SRCAPPLCD_C_D (i_SrcApplCd));



/***************************************************************************
 *
 * CreateMemo
 *
 * Purpose     : Get the ent_seq_no in case of adjustment.
 *
 * Description : - Populate fields
 *		 - Call 'pmm_cr_auto_memo'
 *               - Check returned status 
 *
 * Parameters  : 1. arbtmrec_t 
 *               2. AMTREG_C_D(i_TotAmt)
 *               3. MEMOID_C_D(*ip_MemoId)
 *
 * Return Value: The program's exit status.
 *
 ***************************************************************************/
static FUNCSTS_C_T CreateMemo( arbtmrec_t * ip_btmRec , AMTREG_C_D(i_TotAmt) 
                             , MEMOID_C_D(*ip_MemoId) );
                             
                             

/***************************************************************************
 *
 * CreateAdjustment
 *
 * Purpose     : Create adjustment according to the BTM struct.
 *
 * Description : - Populate fields
 *		 - Call "aramAdjEnv"
 *               - Check returned status 
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec , 
 *               2. AMTREG_C_D(i_TotAmt)
 *               3. const char * ip_Actv
 *               4. MEMOID_C_D(*ip_memo_id)
 *               5. arbtmrec_t * ip_btmRec
 *               6. int i
 *
 * Return Value: The program's exit status.
 *
 ***************************************************************************/
static FUNCSTS_C_T CreateAdjustment( xarcontext_t * xarcontextRec , 
                                     AMTREG_C_D(i_TotAmt) , 
                                     const char * ip_Actv , 
                                     MEMOID_C_D(* ip_memo_id) ,
                                     arbtmrec_t * ip_btmRec , 
                                     int i_indx  );
                                     

/***************************************************************************
 *
 * PopAdj
 *
 * Purpose     : Populate the Adjustment structure.
 *
 * Description : - Populate fields
 *		 -  
 *               -  
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec , 
 *               2. AMTREG_C_D(i_TotAmt)
 *               3. const char * ip_Actv
 *               4. MEMOID_C_D(ip_memo_id)
 *               5. arbtmrec_t * ip_btmRec 
 *               6. int i_Index 
 *               7. aramadj_t * op_AdjustmentRec 
 *
 * Return Value: The program's exit status.
 *
 ***************************************************************************/
static FUNCSTS_C_T PopAdj( xarcontext_t * xarcontextRec , 
                           AMTLRG_C_D(i_TotAmt) , 
                           const char * ip_Actv , 
                           MEMOID_C_D(i_memo_id) ,
                           arbtmrec_t * ip_btmRec ,
                           int i_indx , 
                           aramadj_t * op_AdjustmentRec );
                           
                           

/***************************************************************************
 *
 * CreateCharge
 *
 * Purpose     : Create charge according to the BTM struct.
 *
 * Description : - Populate fields
 *		 - Call "blbn_crcrg" 
 *               - Check returned status 
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec
 *               2. AMTREG_C_D(i_TotAmt)
 *               3. const char * ip_Actv
 *               4. MEMOID_C_D(ip_memo_id)
 *               5. arbtmrec_t * ip_btmRec  
 *               6. int i
 *               7. CHGSEQNO_C_D(*i_tmpChgSeq)
 *
 * Return Value: The program's exit status.
 *
 ***************************************************************************/
static FUNCSTS_C_T CreateCharge( xarcontext_t * xarcontextRec ,
                                 AMTLRG_C_D(i_TotAmt) , 
                                 const char * ip_Actv , 
                                 MEMOID_C_D(* ip_memo_id) ,
                                 arbtmrec_t * ip_btmRec , 
                                 int i_Index ,
                                 CHGSEQNO_C_D(* ip_tmpChgSeq));
                                 

/***************************************************************************
 *
 * PopCharge
 *
 * Purpose     : Populate the chrage structure.
 *
 * Description : - Populate fields
 *		 -  
 *               -  
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec , 
 *               2. AMTREG_C_D(i_TotAmt)
 *               3. const char * ip_Actv
 *               4. MEMOID_C_D(*i_memo_id)
 *               5. arbtmrec_t * ip_btmRec  
 *               6. int i_Index 
 *               7. blbnccrgprm_t * op_ChgParameters
 *               8. t_chg_t * op_ChargeRec
 *
 * Return Value: The program's exit status.
 *
 ***************************************************************************/
static FUNCSTS_C_T PopCharge( xarcontext_t  * xarcontextRec , 
                              AMTREG_C_D     (i_TotAmt) , 
                              const char    * ip_Actv , 
                              MEMOID_C_D     (i_memo_id) ,
                              arbtmrec_t    * ip_btmRec , 
                              int             i_Index , 
                              blbnccrgprm_t * op_ChgParameters , 
                              t_chg_t       * op_ChargeRec );
                              
/* DEF133812 Start */
/***************************************************************************
 *
 * GetEqpInvDet
 *
 * Purpose     : Get RMS_INV details from transaction number
 *
 * Description : - Get RMS_INV details from transaction number
 *
 * Parameters  : 1. xarcontext_t * xarcontextRec ,
 *                              ARTXT16_C_T    (* tmpInvTrxNum),
 *                              RMSLOCID_C_T (* tmpInvStoreID),
 *                              RMSTRXTP_C_T (* tmpInvType),
 *                              ORDEROID_C_T (* tmpInvID)
 *
 * Return Value: SUCCESS
 *
 ***************************************************************************/
static FUNCSTS_C_T GetEqpInvDet(xarcontext_t  * xarcontextRec ,
                                ARTXT16_C_T    (* tmpInvTrxNum),
                                RMSLOCID_C_T (* tmpInvStoreID),
                                RMSTRXTP_C_T (* tmpInvType),
                                ORDEROID_C_T (* tmpInvID));

/* DEF133812 End */

/* Start Change #4 */

static FUNCSTS_C_T pop_titan_comp_trn(xarcontext_t  * xarcontextRec,
					arbtmrec_t *ip_btmRec);

static FUNCSTS_C_T PopulateTitanArr(xarcontext_t  *xarcontextRec ,
                                    arbtmrec_t    *ip_arbtmRec,
				    int            i_indx,
                                    const char *   ip_Actv,
                                    t_chg_t       *iChargeRec,
                                    AMTREG_C_D    (i_TotAmt),
				    aramadj_t     *iAdjustmentRec);

static FUNCSTS_C_T pop_titan_comp_trn( xarcontext_t  * xarcontextRec,
                                        arbtmrec_t *ip_btmRec);

static FUNCSTS_C_T CallTitanEnvelope( xarcontext_t * xarcontextRec, arbtmrec_t   *ip_arbtmRec);

/* End Change #4 */

#endif 
