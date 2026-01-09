import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { showToast } from 'c/utils';

import userId from '@salesforce/user/Id';
import getPickListValues from "@salesforce/apex/BaseController.getPickListValues";
import testgetPickListValues1 from "@salesforce/apex/BaseController.testgetPickListValues1";
import searchInventory from "@salesforce/apex/BaseController.searchInventory";
import searchInventoryProductChanged from "@salesforce/apex/BaseController.searchInventoryProductChanged";
import query from '@salesforce/apex/BaseController.query';
import getCoupledProducts from '@salesforce/apex/CoupledProductController.getCoupledProducts';
import saveCoupledProducts from '@salesforce/apex/CoupledProductController.saveCoupledProducts';
import search from '@salesforce/apex/BaseController.search';

import OPPORTUNITY_OBJECT from "@salesforce/schema/Opportunity";
import WAREHOUSE_CODE from "@salesforce/schema/Opportunity.Warehouse__r.Code__c";
import DIVISION from "@salesforce/schema/Opportunity.Division__c";
import CUSTOMER_CATEGORY_OPP from "@salesforce/schema/Opportunity.Customer_Category__c";
import RECORDTYPEID from '@salesforce/schema/Opportunity.RecordTypeId';
import CUSTOMER_CATEGORY from '@salesforce/schema/Opportunity.Account.Customer_Category__c';
/*import SUPPLIER from '@salesforce/schema/Opportunity.Supplier__c';
import SHIP_TO from '@salesforce/schema/Opportunity.Ship_To__c';
import SUPPLIER_CURRENCY from '@salesforce/schema/Opportunity.Supplier__r.Currency__c';*/
import PRICEBOOK2ID from '@salesforce/schema/Opportunity.Pricebook2Id';
import INDENTSALES from "@salesforce/schema/Opportunity.Indent_Sales__c";

const _FIELDS = [RECORDTYPEID, CUSTOMER_CATEGORY, PRICEBOOK2ID, WAREHOUSE_CODE, DIVISION, CUSTOMER_CATEGORY_OPP, INDENTSALES];

export default class CoupledOppProducts extends LightningElement {
    @api
    recordId;

    @track
    _coupledItems = [];

    @track
    items = [];
    @track
    mapUOMs = [];
    @track
    mapUOM = [];

    UOMs = [];
    getItems = [];
    oppProductTemp = [];
    showSpinner = false;
    sellingFactors = [];
    recentlyViewedProducts = [];
    removedItems = [];
    removedCoupledItems = [];
    showDeleteProductModal = false;
    productToDeleteId;
    productToDeleteIndex;
    productToDeleteParentIndex;
    currentAddedIndex;
    userProfileName;
    isSalesPerson = false;
    wareHouseCode;
    coupledUOM = [{label:"UNT",value:"UNT"}];

    //objectInfo;
    // This wire is used to retrieve the Record Type
    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    objectInfo;

    getUserInfo()
    {
        console.log('UserInfo');
        console.log('userId '+userId);
            query({ q : 'SELECT Id, ProfileId, Profile.Name FROM User WHERe Id =\'' + userId+'\''})
            .then(result => {
                if (result && result.length !== 0) {
                    this.userProfileName = result[0].Profile.Name;
                    console.log(this.userProfileName);
                    if(this.userProfileName  == 'Pansar Sales Person')
                    {
                        this.isSalesPerson = true;
                    }
                }
            });
    }

    opportunity;
    @wire(getRecord, { recordId: '$recordId', fields: _FIELDS })
    getRecord(result) {
        console.log('getRecord');
        console.log(result);
        if (result.data) {
            this.opportunity = result;
            if (
                this.opportunity.data.fields.Warehouse__r.value &&
                this.opportunity.data.fields.Warehouse__r.value.fields.Code__c.value
            ) {
                this.wareHouseCode = this.opportunity.data.fields.Warehouse__r.value.fields.Code__c.value;
                console.log("getRecord WareHouse " + this.wareHouseCode);
                this.queryUOMs();
                //this.queryCoupledProducts();
            } else {
                showToast(
                this,
                "error",
                "Error!",
                "Please input the Warehouse before adding product(s)"
                );
                const closeQA = new CustomEvent("close");
                this.dispatchEvent(closeQA);
            }
        }
    }

    connectedCallback()
    {
        console.log('connectedCallback');
        //this.queryCoupledProducts();
        //this.queryRecentlyViewedProducts();
        this.getUserInfo();
    }

    renderedCallback()
    {
        /*console.log('renderedCallback');
        if (this.recentlyViewedProducts && this.currentAddedIndex)
        {
            this.template.querySelector('c-lookup[data-index="' + this.currentAddedIndex + '"]').setDefaultResults(this.recentlyViewedProducts);
        } */
    }

    queryCoupledProducts()
    {
        console.log('queryCoupledProducts');
        this.showSpinner = true;
        getCoupledProducts({oppId : this.recordId})
        .then(result => {
            if (result && result.length !== 0)
            {
                console.log(result);
                this._coupledItems = result;
                let parentIndex = 0;
                this._coupledItems.forEach(coupledItem => {
                    coupledItem.index = parentIndex++;
                    coupledItem.isRemoveable =(parentIndex == 1 ? false : true);
                    coupledItem.isNew = false;
                    coupledItem.parentProduct.selectedOption = coupledItem.parentProduct.UOM__c;
                    console.log('coupledItem.parentProduct.selectedOption : '+coupledItem.parentProduct.selectedOption);
                    coupledItem.parentProduct.Options = this.coupledUOM;
                    let index = 0;
                    coupledItem.oppProducts.forEach(oppProduct => {
                        let item = oppProduct.oppLineItem;
                        oppProduct.productUrl = '/' + item.Id;
                        oppProduct.index = index++;
                        oppProduct.isNew = false;
                        oppProduct.errors = [];
                        oppProduct.selection = {
                            id: item.Id,
                            sObjectType: 'Product2',
                            icon: 'standard:product',
                            title: item.Name,
                            subtitle: item.Name
                        }
                        oppProduct.isRemoveable = true;
                        oppProduct.config = item.Product2.M_I_Configuration__c;

                        oppProduct.oppLineItem.Margin__c = item.Margin__c;
                        //oppProduct.oppLineItem.Description2__c = item.Description2__c;
                        oppProduct.oppLineItem.ListPrice = item.List_Price__c;
                        oppProduct.oppLineItem.TotalPrice = item.Total_Price_Discount__c;
                        oppProduct.oppLineItem.UOM__c = item.UOM__c;
                        oppProduct.oppLineItem.selectedOption = item.UOM__c;
                        console.log('oppProduct.oppLineItem.selectedOption : '+oppProduct.oppLineItem.selectedOption);

                        this.mapUOMs.forEach((mapitem) => {
                            if (mapitem.key == item.Product2Id) {
                                oppProduct.oppLineItem.Options = mapitem.value;
                                console.log('oppProduct.Options '+ JSON.stringify(oppProduct.oppLineItem.Options));
                            }
                          });

                          //console.log(JSON.stringify(oppProduct));
                          this.oppProductTemp.push(item);
                    });
                    console.log("oppProductTemp");
                    console.log(this.oppProductTemp);
                    searchInventory({items: this.oppProductTemp, wareHouseCode: this.wareHouseCode})
                    .then((result1) => {
                        if (result1 && result1.length !== 0) {
                          console.log(result1);
                          coupledItem.oppProducts.forEach(oppProduct => {
                            if(typeof oppProduct.oppLineItem.Id != 'undefined'){
                            result1.forEach(itemInv => {
                                if(oppProduct.oppLineItem.Id == itemInv.Id)
                                {
                                    oppProduct.oppLineItem.Quantity_Remaining__c = itemInv.Quantity_Remaining__c;
                                    console.log(oppProduct.oppLineItem.Quantity_Remaining__c);
                                }

                            });
                        }

                        });
                        }
                    });

                    coupledItem.oppProducts.push.apply(coupledItem.oppProducts, this.getDefaultProducts(coupledItem.oppProducts));
                });
            }
            this.showSpinner = false;
        })
        .catch(error => {
            console.log('Error in query: ' + JSON.stringify(error));
            this.showSpinner = false;
        });
    }

    UOMChangeHandler(event) {
        console.log("UOMChangeHandler");
        let name = event.target.name;
        let value = event.target.value;
        let parentIndex = event.target.dataset.parentindex;
        let index = event.target.dataset.index;
        {
            console.log('name: ' + name);
            console.log('value: ' + value);
            console.log('parentIndex: ' + parentIndex);
            console.log('index: ' + index);
        }
        let Customer_Category = this.opportunity.data.fields.Customer_Category__c.value;
        console.log(Customer_Category);
        if (typeof value !== "undefined") {
            var selectedUOM = value;
            let coupledItem = this._coupledItems.find(item => item.index == parentIndex);
            let oppProduct = coupledItem.oppProducts.find(item => item.index == index);
            let item = oppProduct.oppLineItem;
            console.log(item);
            {
                query({
                    q:
                    "SELECT Id, List_Price__c, Cost_Price__c, Dealer_List_Price__c, Dealer_Price_Discount__c, Maximum_End_User_Discount__c, Max_Dealer_Price_Discount__c FROM Pansar_Product__c WHERE Product__c = '" +
                    item.Product2Id +
                    "' AND Warehouse__r.code__c = '" +
                    this.wareHouseCode +
                    "' AND UOM__c = '" +
                    selectedUOM +
                    "'"
                })
                    .then((result) => {
                    if (result && result.length !== 0) {
                        console.log(result);
                        result.map((i) => {
                        item.UOM__c = selectedUOM;
                        item.Cost_Price__c = i.Cost_Price__c;
                        item.Discount = 0;

                        if(Customer_Category == 'Dealer'){
                            item.ListPrice = i.Dealer_List_Price__c;
                        }
                        else {
                            item.ListPrice = i.List_Price__c;
                        }

                        item.TotalPrice = item.UnitPrice * item.Quantity;
                        item.Margin__c =((item.UnitPrice - item.Cost_Price__c) * 100) / item.UnitPrice;
                        item.Margin__c = parseFloat(item.Margin__c).toFixed(2);
                        //item.selection = null;
                        });
                        item.errors = [];
                    }
                    })
                    .catch((error) => {
                    console.log("Error in query: " + JSON.stringify(error));
                    showToast(this, "error", "Error!", JSON.stringify(error.body.message));
                    });
                
            }
        }   
        this.calculateCoupledProduct(parentIndex);
      }

      queryUOMs() {
        console.log("queryUOMs");
        getPickListValues({ recordId: this.recordId, wareHouseCode: this.wareHouseCode}).then((result) => {
            if (result && result.length !== 0) {
              console.log(result);
              var conts = result;
              for (var key in conts) {
                this.mapUOMs.push({ value: conts[key], key: key });
                console.log("value is" + conts[key]);
                console.log("key is" + key);
              }
            }
            this.queryCoupledProducts();
          });

      }

    queryRecentlyViewedProducts()
    {
        console.log('queryRecentlyViewedProducts');
        search({ q : 'SELECT Id, Name, ProductCode, UOM__c FROM Product2 ORDER BY LastViewedDate DESC NULLS LAST LIMIT 5', sObjectType: 'Product2', iconName: 'standard:product', title: 'Name', subtitle: 'ProductCode', selectedIds: null})
        .then(result => {
            if (result && result.length !== 0) {
                console.log(result);
                this.recentlyViewedProducts = result;
            }
        });
    }

    get coupledItems()
    {
        console.log('coupledItems');
        if (this._coupledItems.length == 0)
        {
            this.addCoupledProduct();
        }
        return this._coupledItems;
    }

    get isINDENTSALES() {
        return this.opportunity &&
          this.opportunity.data &&
          this.opportunity.data.fields.Indent_Sales__c.value == true
          ? true
          : false;
      }

    coupledInputChanged(event)
    {
        console.log('coupledInputChanged');
        let name = event.target.name;
        let value = event.target.value;
        let index = event.target.dataset.index;
        {
            console.log('name: ' + name);
            console.log('value: ' + value);
            console.log('index: ' + index);
        }
        let coupledItem = this._coupledItems.find(item => item.index == index);
        coupledItem.parentProduct[name] = value;
    }

    inputChanged(event)
    {
        console.log('inputChanged');
        let name = event.target.name;
        let value = event.target.value;
        let parentIndex = event.target.dataset.parentindex;
        let index = event.target.dataset.index;
        {
            console.log('name: ' + name);
            console.log('value: ' + value);
            console.log('parentIndex: ' + parentIndex);
            console.log('index: ' + index);
        }
        let coupledItem = this._coupledItems.find(item => item.index == parentIndex);
        let oppProduct = coupledItem.oppProducts.find(item => item.index == index);
        let item = oppProduct.oppLineItem;
        console.log(item);
        {
            item[name] = value;
            item.UnitPrice = item.UnitPrice || 0;
            item.Quantity = item.Quantity || 0;
            {
                if(name == 'Cost_Price__c')
                {
                    item.Cost_Price__c = item.Cost_Price__c;
                    //item.Margin__c = ((item.UnitPrice - item.Cost_Price__c) *100)/item.UnitPrice;
                    //item.Margin__c = parseFloat(item.Margin__c).toFixed(2);
                }
                else if (name == 'Discount') {
                    item.Discount = item.Discount;
                    item.UnitPrice = item.ListPrice * (1 - (item.Discount * 0.01));
                    item.UnitPrice = parseFloat(item.UnitPrice).toFixed(2);
                    /*if(item.Cost_Price__c)
                    {
                        item.Margin__c = ((item.UnitPrice - item.Cost_Price__c) *100)/item.UnitPrice;
                        item.Margin__c = parseFloat(item.Margin__c).toFixed(2);
                    }*/
                }
                else if (name == 'UnitPrice') {
                    item.UnitPrice = item.UnitPrice;
                    if (item.UnitPrice <= item.ListPrice) {
                        item.Discount = ((item.ListPrice - item.UnitPrice) * 100) / item.ListPrice;
                        item.Discount = parseFloat(item.Discount).toFixed(2);
                    }
                    else item.Discount = 0;

                }

            }


            if (item.Cost_Price__c > 0 && item.UnitPrice > 0) {
                item.Margin__c = ((item.UnitPrice - item.Cost_Price__c) * 100) / item.UnitPrice;
                item.Margin__c = parseFloat(item.Margin__c).toFixed(2);
            }
            else item.Margin__c = 0;

            item.Description2__c = item.Description2__c;
            item.TotalPrice = item.UnitPrice * item.Quantity;
            item.TotalPrice = parseFloat(item.TotalPrice).toFixed(2);
        }
        this.calculateCoupledProduct(parentIndex);
    }

    calculateCoupledProduct(parentIndex)
    {
        let coupledItem = this._coupledItems.find(item => item.index == parentIndex);
        coupledItem.parentProduct.Cost_Price__c = 0;
        coupledItem.parentProduct.List_Price__c = 0;
        coupledItem.parentProduct.Unit_Price__c = 0;
        coupledItem.parentProduct.Margin__c = 0;
        coupledItem.oppProducts.forEach(oppProduct => {
            let item = oppProduct.oppLineItem;
            let costPriceQuantity = (item.Cost_Price__c || 0) * (item.Quantity || 0);
            let listPriceQuantity = (item.ListPrice || 0) * (item.Quantity || 0);
            let TotalPrice = item.TotalPrice || 0;
            coupledItem.parentProduct.Cost_Price__c += (+costPriceQuantity);
            coupledItem.parentProduct.List_Price__c += (+listPriceQuantity);
            coupledItem.parentProduct.Unit_Price__c += (+TotalPrice);
            coupledItem.parentProduct.Margin__c = ((coupledItem.parentProduct.Unit_Price__c - coupledItem.parentProduct.Cost_Price__c) *100)/coupledItem.parentProduct.Unit_Price__c;
        });
    }

    getDefaultProduct(config, placeholderLabel, index)
    {
        let product = {};
        product.index = index;
        product.isNew = true;
        product.oppLineItem = {};
        //product.oppLineItem.sobjectType = 'OpportunityLineItem';
        product.oppLineItem.OpportunityId = this.recordId;
        product.oppLineItem.UnitPrice = 0;
        product.oppLineItem.Cost_Price__c = 0;
        product.oppLineItem.Discount = 0;
        product.oppLineItem.Quantity = 1;
        product.oppLineItem.Margin__c = 0;
        product.oppLineItem.Product2 = {};
        product.selection = {};
        product.errors = [];
        product.config = config;
        product.placeholderLabel = placeholderLabel;
        product.isRemoveable = false;
        return product;
    }

    getDefaultProducts(existingOppProducts)
    {
        let productConfigs = ['Engine','Alternator','Panel','Lubricant','Battery','FAT','Transport'];
        let index = (existingOppProducts && existingOppProducts.length) ? existingOppProducts.length : 0;
        let oppProducts = [];
        productConfigs.forEach(productConfig => {
            if (!existingOppProducts || !existingOppProducts.find(item => item.config == productConfig))
            {
                oppProducts.push(this.getDefaultProduct(productConfig, 'Search ' + productConfig, index++));
                //this.template.querySelector('c-lookup[data-index="' + index + '"]').handleClearSelection();
            }
        });


        return oppProducts;
    }

    addCoupledProduct()
    {
        console.log('addCoupledProduct');
        let count = this._coupledItems.length;
        console.log('count: ' + count);
        let coupledItem = {
            index: count++,
            oppProducts: this.getDefaultProducts(null),
            isRemoveable: (count == 1 ? false : true), //First item in list not removeable
            parentProduct: {
                Enquiry__c: this.recordId,
                Name: 'Coupled Product ' + count,
                Cost_Price__c: 0,
                Margin__c: 0,
                Unit_Price__c: 0,
                Quantity__c: 1,
                UOM__c:'UNT',
                selectedOption:'UNT',
                Options:this.coupledUOM
            },
            remove: false,
            isNew: true
        }
        console.log('coupledItem: ' + coupledItem);
        this._coupledItems.push(coupledItem);
    }

    removeCoupledProduct(event)
    {
        console.log('removeCoupledProduct');
        let index = event.target.dataset.index;
        console.log('index: ' + index);
        let removedItem = this._coupledItems.splice(index, 1);
        removedItem = removedItem[0];
        console.log(removedItem);
        if (removedItem.parentProduct.Id)
        {
            this.removedCoupledItems.push({Id : removedItem.parentProduct.Id});
            removedItem.oppProducts.forEach(item => {
                if (item.oppLineItem.Id)
                {
                    this.removedItems.push({Id : item.oppLineItem.Id});
                }
            });
        }
        let count = this._coupledItems.length;
        let newIndex = 0;
        this._coupledItems.forEach(item => {
            item.index = newIndex++;
            item.isRemoveable = (newIndex == 1 ? false : true) //First item in list not removeable
        });
    }

    toggleCoupledProduct(event)
    {
        event.target.closest('.slds-timeline__item_expandable').classList.toggle('slds-is-open');
    }

    addProduct(event)
    {
        console.log('addProduct');
        let parentIndex = event.target.dataset.parentindex;
        console.log('parentIndex: ' + parentIndex);
        let coupledItem = this._coupledItems.find(item => item.index == parentIndex);
        let product = {};
        product.index = coupledItem.oppProducts.length;
        product.isNew = true;
        product.oppLineItem = {};
        //product.oppLineItem.sobjectType = 'OpportunityLineItem';
        product.oppLineItem.OpportunityId = this.recordId;
        product.oppLineItem.Product2 = {};
        product.selection = {};
        product.errors = [];
        product.config = null;
        product.placeholderLabel = 'Search Product';
        product.isRemoveable = true;
        coupledItem.oppProducts.push(product);
        this.currentAddedIndex = product.index;
    }

    openDeleteProductModal(event)
    {
        this.showDeleteProductModal = true;
        this.productToDeleteId = event.target.dataset.id;
        this.productToDeleteIndex = event.target.dataset.index;
        this.productToDeleteParentIndex = event.target.dataset.parentindex;
    }

    closeDeleteProductModal(event)
    {
        this.showDeleteProductModal = false;
        this.productToDeleteId = null;
        this.productToDeleteIndex = null;
        this.productToDeleteParentIndex = null;
    }

    deleteProduct(event)
    {
        console.log('deleteProduct');
        this.showDeleteProductModal = false;
        this.productToDeleteId = null;
        this.productToDeleteIndex = null;
        this.productToDeleteParentIndex = null;
        console.log(event.target.dataset.index);
        console.log(event.target.dataset.id);
        if (event.target.dataset.id)
        {
            this.removedItems.push({Id : event.target.dataset.id});
        }
        let parentIndex = event.target.dataset.parentindex;
        let index = event.target.dataset.index;
        console.log('parentIndex: ' + parentIndex);
        console.log('index: ' + index);
        let coupledItem = this._coupledItems.find(item => item.index == parentIndex);
        coupledItem.oppProducts.splice(index, 1);
        let newIndex = 0;
        coupledItem.oppProducts.forEach(item => {
            item.index = newIndex++;
        });
        this.calculateCoupledProduct(parentIndex);
        coupledItem.oppProducts.push.apply(coupledItem.oppProducts, this.getDefaultProducts(coupledItem.oppProducts));
    }

    removeProduct(event)
    {
        console.log('removeProduct');
        let parentIndex = event.target.dataset.parentindex;
        let index = event.target.dataset.index;
        console.log('parentIndex: ' + parentIndex);
        console.log('index: ' + index);
        let coupledItem = this._coupledItems.find(item => item.index == parentIndex);
        coupledItem.oppProducts.splice(index, 1);
        let newIndex = 0;
        coupledItem.oppProducts.forEach(item => {
            item.index = newIndex++;
        });
        this.calculateCoupledProduct(parentIndex);
    }

    handleSearch(event)
    {
        console.log('handleSearch');
        let parentIndex =  event.target.dataset.parentindex;
        let index = event.target.dataset.index;
        let config = event.target.dataset.config;
        let searchTerm = event.detail.searchTerm;
        let division = this.opportunity.data.fields.Division__c.value;
        console.log('parentIndex: ' + parentIndex);
        console.log('index: ' + index);
        console.log('config: ' + config);
        console.log('searchTerm: ' + searchTerm);
        // Call Apex endpoint to search for records and pass results to the lookup
        let query = '';
        if (config)
        {
            query =  "SELECT Id, Name, Warehouse__r.code__c, Product__c, Product_Name__c, Product_Cat_Code__c FROM Pansar_Product__c WHERE Product__r.isActive = True AND (Warehouse__r.code__c = '" +
                    this.wareHouseCode + "' OR Product__r.Generic_Product__c = true ) AND (Product__r.Name LIKE '%" +
                    searchTerm +
                    "%' OR Product__r.Product_cat_code__c LIKE '%" +
                    searchTerm +
                    "%' OR Product__r.Description LIKE '%" +
                    searchTerm +
                    "%') limit 20";

            //query = 'SELECT Name, ProductCode FROM Product2 WHERE (Name LIKE \'%' + searchTerm + '%\' OR ProductCODE LIKE \'%' + searchTerm + '%\' OR Description LIKE \'%' + searchTerm + '%\') limit 100';

            //Comment 'M_I_Configuration__c' filter
            //query = 'SELECT Name, ProductCode FROM Product2 WHERE M_I_Configuration__c = \'' + config + '\' AND (Name LIKE \'%' + searchTerm + '%\' OR ProductCODE LIKE \'%' + searchTerm + '%\' OR Description LIKE \'%' + searchTerm + '%\')';
        }
        else
        {
            query =  "SELECT Id, Name, Warehouse__r.code__c, Product__c, Product_Name__c, Product_Cat_Code__c FROM Pansar_Product__c WHERE Product__r.isActive = True AND (Warehouse__r.code__c = '" +
                    this.wareHouseCode + "' OR Product__r.Generic_Product__c = true ) AND (Product__r.Name LIKE '%" +
                    searchTerm +
                    "%' OR Product__r.Product_cat_code__c LIKE '%" +
                    searchTerm +
                    "%' OR Product__r.Description LIKE '%" +
                    searchTerm +
                    "%') limit 20";
            //query = 'SELECT Name, ProductCode FROM Product2 WHERE (Name LIKE \'%' + searchTerm + '%\' OR ProductCODE LIKE \'%' + searchTerm + '%\' OR Description LIKE \'%' + searchTerm + '%\') limit 100';
        }
        //search({q: query, sObjectType: 'Product2', iconName: 'standard:product', title: 'Name', subtitle: 'ProductCode', selectedIds: null})
        search({
            q: query,
            sObjectType: "Pansar_Product__c",
            iconName: "standard:product",
            title: "Product_Name__c",
            subtitle: "Product_Cat_Code__c",
            selectedIds: null
          })
        .then((results) => {
            this.template.querySelector('c-lookup[data-index="' + index + '"][data-parentindex="' + parentIndex + '"]').setSearchResults(results);
        })
        .catch((error) => {
            //this.notifyUser('Lookup Error', 'An error occured while searching with the lookup field.', 'error');
            // eslint-disable-next-line no-console
            console.error('Lookup error', JSON.stringify(error));
            this.errors = [error];
        });
    }

    handleSelectionChange(event)
    {
        console.log('handleSelectionChange');
        let parentIndex = event.target.dataset.parentindex;
        let index = event.target.dataset.index;
        console.log('parentIndex: ' + parentIndex);
        console.log('index: ' + index);
        console.log(event.detail[0]);
        let pricebook2Id = this.opportunity.data.fields.Pricebook2Id.value;
        console.log('pricebook2Id:' + pricebook2Id);
        let Customer_Category = this.opportunity.data.fields.Customer_Category__c.value;
        let coupledItem = this._coupledItems.find(item => item.index == parentIndex);
        let oppProduct = coupledItem.oppProducts.find(item => item.index == index);
        let item = oppProduct.oppLineItem;
        {
            if (typeof event.detail[0] !== 'undefined')
            {
            item.Product2Id = event.detail[0];
            testgetPickListValues1({
                productId: item.Product2Id,
                wareHouseCode: this.wareHouseCode
            })
            .then((result) => {
              if (result && result.length !== 0) {
                console.log(result);
                var conts = result;
                for (var key in conts) {
                  this.mapUOM.push({ value: conts[key], key: key });
                  console.log(JSON.stringify(conts[key]));
                  console.log("key is" + key);
                }
                console.log(this.mapUOM);

                this.mapUOM.forEach((mapitem) => {
                  if (mapitem.key == item.Product2Id && item.id == null) {
                    item.Options = mapitem.value;
                    if(mapitem.value.length == 1){
                        var mapitemJSON = JSON.stringify(mapitem.value);
                        var obj = JSON.parse(mapitemJSON);
                        item.selectedOption = obj[0].value;
                        item.UOM__c = item.selectedOption;
                        console.log('selectedOption '+item.selectedOption);
                    }
                  }
                });

                if(typeof item.selectedOption !== "undefined"){
                    //this.wareHouseCode = this.opportunity.data.fields.Warehouse__r.value.fields.Code__c.value;
                    console.log(this.wareHouseCode);
                    query({ q : 'SELECT Id, List_Price__c, Cost_Price__c, Dealer_List_Price__c, Dealer_Price_Discount__c, Maximum_End_User_Discount__c, Max_Dealer_Price_Discount__c FROM Pansar_Product__c WHERE Product__c = \'' +
                            item.Product2Id + '\' AND Warehouse__r.code__c = \'' +  this.wareHouseCode + '\' AND UOM__c = \'' +  item.selectedOption + '\''})
                        .then((result) => {
                          if (result && result.length !== 0) {
                            console.log(result);
                            result.map((i) => {
                                if(this.opportunity.data.fields.Indent_Sales__c.value == true && this.isSalesPerson == true){
                                    item.Cost_Price__c = 0;
                                }
                                else item.Cost_Price__c = i.Cost_Price__c;
                                console.log("item.Cost_Price__c 11 "+item.Cost_Price__c);

                                if(Customer_Category == 'Dealer'){
                                    item.ListPrice = i.Dealer_List_Price__c;
                                    //item.UnitPrice = i.Dealer_List_Price__c;
                                }
                                else {
                                    item.ListPrice = i.List_Price__c;
                                    //item.UnitPrice = i.List_Price__c;
                                }

                                item.Margin__c  = null;
                                //item.TotalPrice = item.UnitPrice * item.Quantity;
                                //item.Margin__c = ((item.UnitPrice - item.Cost_Price__c) *100)/item.UnitPrice;
                                //item.Margin__c = parseFloat(item.Margin__c).toFixed(2);
                                item.selection = null;
                            });
                            item.errors = [];
                          }
                        })
                        .catch((error) => {
                          console.log("Error in query: " + JSON.stringify(error));
                          showToast(this, "error", "Error!", JSON.stringify(error.body.message));
                        });
                    }

              }
            })
            .catch((error) => {
              console.log(JSON.stringify(error));
              showToast(this, "error", "Error!", JSON.stringify(error.body.message));
            });

          query({
            q:
              "SELECT Product2.ProductCode,Product2.Cost_Price__c ,Product2.Description, UnitPrice FROM PricebookEntry WHERE Product2Id = '" +
              item.Product2Id +
              "' AND Pricebook2Id = '" +
              pricebook2Id +
              "'"
          })
            .then((result) => {
              if (result && result.length !== 0) {
                console.log(result);
                result.map((i) => {
                  item.Product2 = {};
                  item.Product2.ProductCode = i.Product2.ProductCode;
                  //item.Product2.UOM__c = i.Product2.UOM__c;
                  item.Description2__c = i.Product2.Description;
                  item.selection = null;
                });
                item.errors = [];
              }
            })
            .catch((error) => {
              console.log("Error in query: " + JSON.stringify(error));
              showToast(this, "error", "Error!", JSON.stringify(error.body.message));
            });

          searchInventoryProductChanged({
            productId: item.Product2Id,
            wareHouseCode: this.wareHouseCode
          })
            .then((result) => {
              if (result && result.length !== 0) {
                console.log("Quantity_Remaining__c");
                console.log(result);
                item.Quantity_Remaining__c = result;
              }
            })
            .catch((error) => {
              console.log("Error in query: " + JSON.stringify(error));
              showToast(this, "error", "Error!", JSON.stringify(error.body.message));
            });


                /*item.Product2Id = event.detail[0];
                query({ q : 'SELECT Product2.ProductCode,Product2.Cost_Price__c ,Product2.Description, UnitPrice FROM PricebookEntry WHERE Product2Id = \'' +  item.Product2Id + '\' AND Pricebook2Id = \'' + pricebook2Id + '\''})
                .then(result => {
                    if (result && result.length !== 0) {
                        console.log(result);
                        result.map(i => {
                            item.Product2 = {};
                            item.Product2.ProductCode = i.Product2.ProductCode;
                            item.Product2.UOM__c = i.Product2.UOM__c;
                            item.Description2__c = i.Product2.Description;
                            item.Cost_Price__c = i.Product2.Cost_Price__c;
                            item.Discount = 0;
                            item.ListPrice = i.UnitPrice;
                            item.UnitPrice = i.UnitPrice;
                            item.TotalPrice = item.UnitPrice * item.Quantity;
                            oppProduct.selection = null;
                        });
                        oppProduct.errors = [];
                        this.calculateCoupledProduct(parentIndex);
                    }
                })
                .catch(error => {
                    console.log('Error in query: ' + JSON.stringify(error));
                });*/
            }
            else{
                item.Product2Id = null;
                item.Product2 = {};
                item.UnitPrice = 0;
                item.Quantity = 1;
                item.TotalPrice = null;
                item.Discount = 0;
                item.Cost_Price__c = 0;
                item.ListPrice = null;
                item.Margin__c = 0;
                item.Quantity_Remaining__c = null;
                item.Options = null;
                item.Description2__c = null;
                item.selectedOption = null;
                item.UOM__c = null;
                //item.oppLineItem.errors = [{id: "1", message: "Complete this field."}];
                this.calculateCoupledProduct(parentIndex);
            }
        }
    }

    saveCoupledProducts(event)
    {
        console.log('saveCoupledProducts');
        let close = event.target.dataset.close;
        console.log('close: ' + close);
        this.showSpinner = true;
        let allValid = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);

        if (allValid)
        {
            let coupledProducts = [];
            this._coupledItems.forEach(coupledItem => {
                let coupledProduct = {};
                coupledProduct.parentProduct = coupledItem.parentProduct;
                delete coupledProduct.parentProduct.Opportunity_Product__r;
                coupledProduct.oppProducts = [];
                coupledItem.oppProducts.forEach(oppProductItem => {
                    let item = oppProductItem.oppLineItem;
                    if (item.Product2Id)
                    {
                        let oppProduct = {}
                        oppProduct.oppLineItem = {};
                        oppProduct.oppLineItem.Amount_In_Supplier_Currency__c = parseFloat(item.Amount_In_Supplier_Currency__c);
                        oppProduct.oppLineItem.Selling_Factor__c = parseFloat(item.Selling_Factor__c);
                        oppProduct.oppLineItem.Quantity = parseFloat(item.Quantity);
                        oppProduct.oppLineItem.UnitPrice = parseFloat(item.UnitPrice);
                        //oppProduct.oppLineItem.Description2__c = item.Description2__c;
                        oppProduct.oppLineItem.Margin__c = item.Margin__c;
                        oppProduct.oppLineItem.Cost_Price__c = item.Cost_Price__c;
                        oppProduct.oppLineItem.Discount = item.Discount;
                        oppProduct.oppLineItem.UOM__c = item.UOM__c;
                        oppProduct.oppLineItem.List_Price__c = item.ListPrice;
                        oppProduct.oppLineItem.Total_Price_Discount__c = item.TotalPrice;

                        if (oppProductItem.isNew)
                        {
                            //sobj.sobjectType = 'OpportunityLineItem';
                            oppProduct.oppLineItem.Product2Id = item.Product2Id;
                            oppProduct.oppLineItem.OpportunityId = item.OpportunityId;
                            //sobj.Margin__c = item.Margin__c;
                        }
                        else
                        {
                            oppProduct.oppLineItem.Id = item.Id;
                        }
                        coupledProduct.oppProducts.push(oppProduct);
                    }
                });
                coupledProducts.push(coupledProduct);
            });
            saveCoupledProducts({ coupledProducts : coupledProducts, parentProductsToDelete: this.removedCoupledItems, oppLineItemsToDelete: this.removedItems})
            .then(result => {
                this.showSpinner = false;
                if (close == 'true')
                {
                    const closeQA = new CustomEvent('close');
                    this.dispatchEvent(closeQA);
                }
                else
                {
                    try{
                        let lookups = this.template.querySelectorAll('c-lookup');
                        for(var i=0; i<lookups.length ;i++)
                        {
                            lookups[i].handleClearSelection();
                        }
                    }
                    catch(e)
                    {
                        console.log(e);
                    }

                    //this.template.querySelector('c-lookup[data-index="' + 4 + '"]').handleClearSelection();
                    this.queryUOMs();
                    //this.queryCoupledProducts();
                    this.removedItems = [];
                    this.removedCoupledItems = [];
                }
            })
            .catch(error => {
                console.log('Error in save: ' + JSON.stringify(error));
                let errorMessage = (error && error.body && error.body.pageErrors && error.body.pageErrors[0] && error.body.pageErrors[0].message) || '';
                showToast(this, 'error', 'Error!', errorMessage);
                this.showSpinner = false;
            });
        }
        else
        {
            this.showSpinner = false;
        }
    }
}