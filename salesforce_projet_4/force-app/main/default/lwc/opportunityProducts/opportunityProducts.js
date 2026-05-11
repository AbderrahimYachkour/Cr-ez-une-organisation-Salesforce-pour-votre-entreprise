import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getOpportunityProducts from '@salesforce/apex/OpportunityProductController.getOpportunityProducts';
import getCurrentUserProfileName from '@salesforce/apex/OpportunityProductController.getCurrentUserProfileName';
import deleteOpportunityLineItem from '@salesforce/apex/OpportunityProductController.deleteOpportunityLineItem';

import LBL_PRODUCT_NAME from '@salesforce/label/c.lbl_Product_Name';
import LBL_QUANTITY from '@salesforce/label/c.lbl_Quantity';
import LBL_UNIT_PRICE from '@salesforce/label/c.lbl_Unit_Price';
import LBL_TOTAL_PRICE from '@salesforce/label/c.lbl_Total_Price';
import LBL_QUANTITY_IN_STOCK from '@salesforce/label/c.lbl_Quantity_In_Stock';
import LBL_DELETE from '@salesforce/label/c.lbl_Delete';
import LBL_SEE_PRODUCT from '@salesforce/label/c.lbl_See_Product';
import LBL_OPPORTUNITY_PRODUCTS from '@salesforce/label/c.lbl_Opportunity_Products';
import LBL_QUANTITY_PROBLEM from '@salesforce/label/c.lbl_Quantity_Problem_Message';
import LBL_NO_PRODUCT_LINES from '@salesforce/label/c.lbl_No_Product_Lines_Message';

const PROBLEM_CELL_CLASS = 'slds-text-color_destructive slds-text-title_bold';

export default class OpportunityProducts extends NavigationMixin(LightningElement) {
    @api recordId;

    products;
    isAdmin = false;
    wiredProductsResult;
    error;

    labels = {
        title: LBL_OPPORTUNITY_PRODUCTS,
        empty: LBL_NO_PRODUCT_LINES,
        quantityProblem: LBL_QUANTITY_PROBLEM,
        productName: LBL_PRODUCT_NAME,
        quantity: LBL_QUANTITY,
        unitPrice: LBL_UNIT_PRICE,
        totalPrice: LBL_TOTAL_PRICE,
        quantityInStock: LBL_QUANTITY_IN_STOCK,
        delete: LBL_DELETE,
        seeProduct: LBL_SEE_PRODUCT
    };

    @wire(getCurrentUserProfileName)
    wiredProfile({ data, error }) {
        if (data) {
            this.isAdmin = data === 'System Administrator' || data === 'Administrateur système';
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getOpportunityProducts, { opportunityId: '$recordId' })
    wiredProducts(result) {
        this.wiredProductsResult = result;
        if (result.data) {
            this.products = result.data.map(oli => {
                const stock = oli.Product2 ? oli.Product2.QuantityInStock__c : null;
                const hasProblem = stock !== null && stock !== undefined
                    ? (stock - oli.Quantity < 0)
                    : false;
                return {
                    id: oli.Id,
                    productId: oli.Product2Id,
                    name: oli.Product2 ? oli.Product2.Name : null,
                    quantity: oli.Quantity,
                    unitPrice: oli.UnitPrice,
                    totalPrice: oli.TotalPrice,
                    quantityInStock: stock,
                    hasProblem: hasProblem,
                    stockCellClass: hasProblem ? PROBLEM_CELL_CLASS : ''
                };
            });
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.products = undefined;
        }
    }

    get hasProducts() {
        return this.products && this.products.length > 0;
    }

    get hasAnyProblem() {
        return this.products && this.products.some(p => p.hasProblem);
    }

    handleDelete(event) {
        const lineItemId = event.currentTarget.dataset.id;
        deleteOpportunityLineItem({ lineItemId })
            .then(() => refreshApex(this.wiredProductsResult))
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Line deleted',
                    variant: 'success'
                }));
            })
            .catch(err => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: (err && err.body && err.body.message) || 'Delete failed',
                    variant: 'error'
                }));
            });
    }

    handleViewProduct(event) {
        const productId = event.currentTarget.dataset.productId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: productId,
                objectApiName: 'Product2',
                actionName: 'view'
            }
        });
    }
}
