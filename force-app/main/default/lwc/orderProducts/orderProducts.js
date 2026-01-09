import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { showToast } from "c/utils";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import PRODUCT_OBJECT from '@salesforce/schema/Product2';
import UOM_FIELD from '@salesforce/schema/Product2.UOM__c';

import getPickListValues from "@salesforce/apex/BaseController.getPickListValues";
import testgetPickListValues1 from "@salesforce/apex/BaseController.testgetPickListValues1";
import searchInventory from "@salesforce/apex/BaseController.searchInventory";
import searchInventoryProductChanged from "@salesforce/apex/BaseController.searchInventoryProductChanged";
import userId from "@salesforce/user/Id";
import query from "@salesforce/apex/BaseController.query";
import saveAndDelete from "@salesforce/apex/BaseController.saveAndDelete";
import search from "@salesforce/apex/BaseController.search";

import ORDER_OBJECT from '@salesforce/schema/Order';

import RECORDTYPEID from '@salesforce/schema/Order.RecordTypeId';
import WAREHOUSE_CODE from '@salesforce/schema/Order.Warehouse__r.Code__c';
import DIVISION from "@salesforce/schema/Order.Division__c";
import CUSTOMER_CATEGORY from "@salesforce/schema/Order.Price_List_Type__c";
import PRICEBOOK2ID from '@salesforce/schema/Order.Pricebook2Id';
import INDENTSALES from "@salesforce/schema/Order.Indent_Sales__c";
import CREATEDDATE from "@salesforce/schema/Order.CreatedDate";

const _FIELDS = [RECORDTYPEID, PRICEBOOK2ID, WAREHOUSE_CODE, INDENTSALES, DIVISION, CUSTOMER_CATEGORY, CREATEDDATE];

export default class OrderProducts extends LightningElement {
  @api
  recordId;

  @track items;
  @track newItems = [];
  @track mapUOMs = [];
  @track mapUOM = [];

  UOMs = [];
  getItems = [];
  showSpinner = false;
  sellingFactors = [];
  recentlyViewedProducts = [];
  removedItems = [];
  showDeleteProductModal = false;
  productToDeleteId;
  productToDeleteIndex;
  currentAddedIndex;
  currentAddedNewIndex;
  add7Default = true;
  userProfileName;
  isSalesPerson = false;
  wareHouseCode;

  //objectInfo;
  // This wire is used to retrieve the Record Type
  @wire(getObjectInfo, { objectApiName: PRODUCT_OBJECT })
  objectInfo;

  @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: UOM_FIELD })
  UOMPicklistValues;

  userData;
  getUserInfo() {
    console.log('UserInfo');
    console.log('userId ' + userId);
    query({ q: 'SELECT Id, ProfileId, Profile.Name FROM User WHERe Id =\'' + userId + '\'' })
      .then(result => {
        if (result && result.length !== 0) {
          this.userProfileName = result[0].Profile.Name;
          console.log(this.userProfileName);
          if (this.userProfileName == 'Pansar Sales Person') {
            this.isSalesPerson = true;
          }
        }
      });
  }

  order;
  @wire(getRecord, { recordId: '$recordId', fields: _FIELDS })
  getRecord(result) {
    console.log('getRecord');
    console.log(result);
    if (result.data) {
      this.order = result;
      if (this.order.data.recordTypeInfo.name == 'Spare Parts') {
        this.querySellingFactors();
      }

      if (this.order.data.fields.Warehouse__r.value && this.order.data.fields.Warehouse__r.value.fields.Code__c.value) {
        this.wareHouseCode = this.order.data.fields.Warehouse__r.value.fields.Code__c.value;
        console.log("getRecord WareHouse " + this.wareHouseCode);
        this.queryUOMs();
        //this.queryLineItems();
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

  connectedCallback() {
    console.log("connectedCallback");
    this.getUserInfo();
  }

  renderedCallback() {
  }

  queryLineItems() {
    let getItems = [];
    query({ q: 'SELECT Id, New_Product__c,Total_Price_Discount__c, Description2__c, Quantity_Remaining__c, UOM__c,List_Price__c, Cost_Price__c, Order.Warehouse__r.code__c, Product2.Name, Product2.ProductCode, Product2.Description, Product2.UOM__c, Product2.M_I_Configuration__c, Product2.Cost_Price__c, Quantity, Margin__c, UnitPrice, ListPrice, TotalPrice, Discount__c FROM OrderItem WHERE OrderId = \'' + this.recordId + '\' ORDER BY Product2.Name ASC' })
      .then((result) => {
        if (result && result.length !== 0) {
          console.log("queryLineItems");
          console.log(result);
          if (this.wareHouseCode) {
            searchInventory({
              items: result,
              wareHouseCode: this.wareHouseCode
            }).then((result1) => {
              if (result1 && result1.length !== 0) {
                console.log(result1);
                getItems = result1;
              } else {
                getItems = result;
              }

              const clone = JSON.parse(JSON.stringify(getItems));
              let index = 0;
              this.items = clone.map((item) => {
                item.productUrl = "/" + item.Id;
                item.index = index++;
                item.isNew = false;
                item.errors = [];
                item.selection = {
                  id: item.Id,
                  sObjectType: "Product2",
                  icon: "standard:product",
                  title: item.Name,
                  subtitle: item.Name
                };

                item.isRemoveable = true;
                item.config = item.Product2.M_I_Configuration__c;
                item.Cost_Price__c = item.Cost_Price__c;
                item.ListPrice = item.List_Price__c;
                item.Discount = item.Discount__c;
                item.TotalPrice = item.Total_Price_Discount__c;
                item.Margin__c = item.Margin__c;

                if (!item.Description2__c) {
                  item.Description2__c = item.Product2.Description;
                }

                if (item.UOM__c) {
                  item.selectedOption = item.UOM__c;
                  console.log("item.selectedOption : " + item.selectedOption);
                }

                if (item.New_Product__c != true) {
                  this.mapUOMs.forEach((mapitem) => {
                    if (mapitem.key == item.Product2Id) {
                      item.Options = mapitem.value;
                      console.log('item.Options  ' + JSON.stringify(item.Options));
                    }
                  });
                }
                else {
                  item.Options = [{ label: item.UOM__c, value: item.UOM__c }];
                }

                return item;
              });
            });
          }
        } else {
          this.items = [];
        }
      })
      .catch((error) => {
        console.log("Error in query: " + JSON.stringify(error));
        showToast(this, "error", "Error!", JSON.stringify(error.body.message));
      });
  }

  queryUOMs() {
    console.log("queryUOMs");
    getPickListValues({ recordId: this.recordId, wareHouseCode: this.wareHouseCode }).then((result) => {
      if (result && result.length !== 0) {
        console.log(result);
        var conts = result;
        for (var key in conts) {
          this.mapUOMs.push({ value: conts[key], key: key });
          console.log("value is" + conts[key]);
          console.log("key is" + key);
        }
      }
      this.queryLineItems();
    });
  }

  UOMChangeHandler(event) {
    console.log("UOMChangeHandler");
    console.log(event.target.dataset.index);
    console.log(event.target.value);
    let Customer_Category = this.order.data.fields.Price_List_Type__c.value;
    console.log(Customer_Category);

    this.items.forEach((item) => {
      if (item.index == event.target.dataset.index) {
        if (typeof event.target.value !== "undefined") {
          var selectedUOM = event.target.value;
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

                  if (Customer_Category == 'Dealer') {
                    item.ListPrice = i.Dealer_List_Price__c;
                  }
                  else {
                    item.ListPrice = i.List_Price__c;
                  }

                  item.TotalPrice = item.UnitPrice * item.Quantity;
                  item.Margin__c =
                    ((item.UnitPrice - item.Cost_Price__c) * 100) /
                    item.UnitPrice;
                  item.Margin__c = parseFloat(item.Margin__c).toFixed(2);
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
    });
  }

  querySellingFactors() {
    console.log('querySellingFactors');
    if (this.order && this.order.data) {
      //Query selling factors        
      query({ q: 'SELECT Dealer_Selling_Factor__c,End_User_Selling_Factor__c,Price_Range_From__c,Price_Range_To__c FROM Selling_Factor__c WHERE Active__c = TRUE AND Supplier__c = \'' + this.order.data.fields.Supplier__c.value + '\' AND Ship_To__c = \'' + this.order.data.fields.Ship_To__c.value + '\'  ORDER BY CreatedDate ASC' })
        .then(result => {
          if (result && result.length !== 0) {
            console.log(result);
            this.sellingFactors = result;
          }
        });
    }
  }

  queryRecentlyViewedProducts() {
    console.log('queryRecentlyViewedProducts');
    search({ q: 'SELECT Id, Name, ProductCode, UOM__c FROM Product2 ORDER BY LastViewedDate DESC NULLS LAST LIMIT 5', sObjectType: 'Product2', iconName: 'standard:product', title: 'Name', subtitle: 'ProductCode', selectedIds: null })
      .then(result => {
        if (result && result.length !== 0) {
          console.log(result);
          this.recentlyViewedProducts = result;
        }
      });
  }

  get supplierCurrency() {
    return (this.order && this.order.data && this.order.data.fields.Supplier__r.value ? this.order.data.fields.Supplier__r.value.fields.Currency__c.displayValue : null);
  }

  get lineItems() {
    console.log('lineItems');
    if (this.order && this.order.data && this.order.data.recordTypeInfo.name == 'Customised Engineering Solution' && this.items && this.add7Default == true)
    //&& this.items.length == 0)
    {
      this.addDefaultProduct('Engine', 'Search Engine');
      this.addDefaultProduct('Alternator', 'Search Alternator');
      this.addDefaultProduct('Panel', 'Search Panel');
      this.addDefaultProduct('Lubricant', 'Search Lubricant');
      this.addDefaultProduct('Battery', 'Search Battery');
      this.addDefaultProduct('FAT', 'Search FAT');
      this.addDefaultProduct('Transport', 'Search Transport');
    }
    if (this.items)
      return this.items;
    else
      return [];
  }


  get newlineItems() {
    console.log("get newItems");
    if (this.newItems) return this.newItems;
    else return [];
  }

  get isCES() {
    return (this.order && this.order.data && this.order.data.recordTypeInfo.name == 'Standalone Order' ? true : false);
  }

  get isINDENTSALES() {
    return this.order &&
      this.order.data &&
      this.order.data.fields.Indent_Sales__c.value == true
      ? true
      : false;
  }

  inputChanged(event) {
    console.log('inputChanged');
    console.log(event.target.name);
    this.add7Default = false;
    console.log(event.target.dataset.index);
    const clone = JSON.parse(JSON.stringify(this.items));
    this.items = clone.map(item => {           
      if (item.index == event.target.dataset.index) {

        item[event.target.name] = event.target.value;
        item.UnitPrice = item.UnitPrice || 0;
        item.Quantity = item.Quantity || 0;

        if (this.order.data.recordTypeInfo.name == 'Spare Parts') {
          item.Amount_In_Supplier_Currency__c = item.Amount_In_Supplier_Currency__c || 0;
          item.Selling_Factor__c = item.Selling_Factor__c || 0;
          if (event.target.name == 'Amount_In_Supplier_Currency__c') {
            let sellingFactor = this.sellingFactors.find(i =>
              i.Price_Range_From__c <= item.Amount_In_Supplier_Currency__c &&
              i.Price_Range_To__c >= item.Amount_In_Supplier_Currency__c);
            console.log(sellingFactor);
            if (sellingFactor) {
              let customCategory = this.order.data.fields.Account.value.fields.Customer_Category__c.value;
              if (customCategory == 'Dealer') {
                item.Selling_Factor__c = sellingFactor.Dealer_Selling_Factor__c;
              }
              else if (customCategory == 'End User') {
                item.Selling_Factor__c = sellingFactor.End_User_Selling_Factor__c;
              }
            }

            item.UnitPrice = item.Amount_In_Supplier_Currency__c * item.Selling_Factor__c;
            item.UnitPrice = parseFloat(item.UnitPrice).toFixed(2);
          }
        }
        else if (this.order.data.recordTypeInfo.name != 'Spare Parts')
        {

          if (event.target.name == "Cost_Price__c") {
            item.Cost_Price__c = item.Cost_Price__c;

          } else if (event.target.name == "Discount") {
            item.Discount = item.Discount;
            item.UnitPrice = item.ListPrice * (1 - item.Discount * 0.01);
            item.UnitPrice = parseFloat(item.UnitPrice).toFixed(2);

          } else if (event.target.name == "UnitPrice") {
            item.UnitPrice = item.UnitPrice;
            if (item.UnitPrice <= item.ListPrice) {
              item.Discount =
                ((item.ListPrice - item.UnitPrice) * 100) / item.ListPrice;
              item.Discount = parseFloat(item.Discount).toFixed(2);
            } else item.Discount = 0;

          }

          if (item.Cost_Price__c > 0 && item.UnitPrice > 0) {
            item.Margin__c =
              ((item.UnitPrice - item.Cost_Price__c) * 100) / item.UnitPrice;
            item.Margin__c = parseFloat(item.Margin__c).toFixed(2);
          }
          else item.Margin__c = 0;
        }

        item.Description2__c = item.Description2__c;
        item.TotalPrice = item.UnitPrice * item.Quantity;
        item.TotalPrice = parseFloat(item.TotalPrice).toFixed(2);
      }
      return item;
    });
    //console.log(this.items);
  }

  newInputChanged(event) {
    console.log('newInputChanged');
    let name = event.target.name;
    let value = event.target.value;
    let index = event.target.dataset.index;
    {
      console.log('name: ' + name);
      console.log('value: ' + value);
      console.log('index: ' + index);
    }
    const clone = JSON.parse(JSON.stringify(this.newItems));
    this.newItems = clone.map((item) => {
      //console.log('item.index:' + item.index);
      if (item.index == event.target.dataset.index) {
        item[name] = value;

        if (name == 'Name') {
          item.Product2.Name = value;
        }
        else if (name == 'ProductCode') {
          item.Product2.ProductCode = value;
          item.Product2.ERP_Id__c = value;
        }
        else if (name == 'Description') {
          item.Product2.Description = value;
          item.Description2__c = value;
        }
        else if (name == "Discount") {
          item.Discount = item.Discount;
          item.UnitPrice = item.ListPrice * (1 - item.Discount * 0.01);
          item.UnitPrice = parseFloat(item.UnitPrice).toFixed(2);
        }
        else if (name == "UnitPrice") {
          item.UnitPrice = item.UnitPrice;
          item.Discount =
            ((item.ListPrice - item.UnitPrice) * 100) / item.ListPrice;
          item.Discount = parseFloat(item.Discount).toFixed(2);
        }
        else if (name == 'UOM__c') {
          item.Product2.UOM__c = value;
          item.UOM__c = value;
        }

        if (item.Cost_Price__c > 0) {
          item.Margin__c =
            ((item.UnitPrice - item.Cost_Price__c) * 100) / item.UnitPrice;
          item.Margin__c = parseFloat(item.Margin__c).toFixed(2);
        }
        else item.Margin__c = 0;

        item.TotalPrice = item.UnitPrice * item.Quantity;
        item.TotalPrice = parseFloat(item.TotalPrice).toFixed(2);


        item.Product2.IsActive = true;
        item.Product2.New_Product__c = true;
        if (item.Discount < 0) item.Discount = 0;

      }
      return item;
    });
  }

  addDefaultProduct(config, placeholderLabel) {
    let product = {};
    product.index = this.items.length;
    product.isNew = true;
    product.sobjectType = 'OrderItem';
    product.OrderId = this.recordId;
    product.UnitPrice = 0;
    product.Cost_Price__c = 0;
    product.Discount = 0;
    product.Quantity = 1;
    product.Margin__c = 0;
    product.Product2 = {};
    product.selection = {};
    product.errors = [];
    product.config = config;
    product.placeholderLabel = placeholderLabel;
    product.isRemoveable = false;
    this.items.push(product);
  }

  addProduct() {
    let product = {};
    product.index = this.items.length;
    product.isNew = true;
    product.sobjectType = 'OrderItem';
    product.OrderId = this.recordId;
    product.Product2 = {};
    product.selection = {};
    product.errors = [];
    product.config = null;
    product.placeholderLabel = 'Search Product';
    product.isRemoveable = true;
    this.items.push(product);
    this.currentAddedIndex = product.index;
    this.add7Default = false;
    console.log(this.items);
  }

  addNewProduct() {
    console.log('addNewProduct');
    console.log(this.newItems.length);
    let product = {};
    product.index = this.newItems.length;
    product.isNew = true;
    product.sobjectType = "OrderItem";
    product.OrderId = this.recordId;
    product.Product2 = {};
    product.selection = {};
    product.errors = [];
    product.config = null;
    product.placeholderLabel = "New Product";
    product.isRemoveable = true;
    product.ListPrice = 0;
    product.Cost_Price__c = 0;
    product.Discount = 0;
    this.newItems.push(product);
    this.currentAddedNewIndex = product.index;
    this.add7Default = false;
  }

  openDeleteProductModal(event) {
    this.showDeleteProductModal = true;
    this.productToDeleteId = event.target.dataset.id;
    this.productToDeleteIndex = event.target.dataset.index;
  }

  closeDeleteProductModal(event) {
    this.showDeleteProductModal = false;
    this.productToDeleteId = null;
    this.productToDeleteIndex = null;
  }

  deleteProduct(event) {
    console.log('deleteProduct');
    this.add7Default = false;
    this.showDeleteProductModal = false;
    this.productToDeleteId = null;
    this.productToDeleteIndex = null;
    console.log(event.target.dataset.index);
    console.log(event.target.dataset.id);
    if (event.target.dataset.id) {
      this.removedItems.push({ Id: event.target.dataset.id });
    }

    this.items.splice(event.target.dataset.index, 1);
    let index = 0;
    this.items.forEach(item => {
      item.index = index++;
    });
  }

  removeProduct(event) {
    console.log('removeProduct');
    console.log(event.target.dataset.index);
    this.items.splice(event.target.dataset.index, 1);
    let index = 0;
    this.items.forEach(item => {
      item.index = index++;
    });
  }

  removeNewProduct(event) {
    console.log("removeNewProduct");
    console.log(event.target.dataset.index);
    this.newItems.splice(event.target.dataset.index, 1);
    let index = 0;
    this.newItems.forEach((item) => {
      item.index = index++;
    });
  }

  handleSearch(event) {
    console.log("handleSearch");
    console.log(event.target.dataset.index);
    let index = event.target.dataset.index;
    let config = event.target.dataset.config;
    let searchTerm = event.detail.searchTerm;
    let division = this.order.data.fields.Division__c.value;
    // Call Apex endpoint to search for records and pass results to the lookup
    let query = "";
    if (config) {
      query =
        "SELECT Name, ProductCode FROM Product2 WHERE M_I_Configuration__c = '" +
        config +
        "' AND (Name LIKE '%" +
        searchTerm +
        "%' OR ProductCode LIKE '%" +
        searchTerm +
        "%' OR Description LIKE '%" +
        searchTerm +
        "%')";
    } else {
      query =
        /*"SELECT Id, Name, Warehouse__r.code__c, Product__c, Product_Name__c, Product_Cat_Code__c FROM Pansar_Product__c WHERE Product__r.isActive = True AND (Warehouse__r.code__c = '" +  
        this.wareHouseCode + "' OR Product__r.Generic_Product__c = true ) AND (Product__r.Name LIKE '%" +
        searchTerm +
        "%' OR Product__r.Product_cat_code__c LIKE '%" +
        searchTerm +
        "%' OR Product__r.Description LIKE '%" +
        searchTerm +
        "%') limit 20";*/

        "SELECT Id, Product__c, Product_Name__c, Product_Cat_Code__c, Quantity_Remaining__c FROM Inventory__c where Product__r.isActive = True AND Inventory_Status__c = 'Active' AND (Warehouse__r.Code__c = '" +
        this.wareHouseCode + "' OR Product__r.Generic_Product__c = true ) AND (Product__r.Name LIKE '%" +
        searchTerm +
        "%' OR Product__r.Product_cat_code__c LIKE '%" +
        searchTerm +
        "%' OR Product__r.Description LIKE '%" +
        searchTerm +
        "%') limit 20";

    }
    search({
      q: query,
      sObjectType: "Inventory__c",
      iconName: "standard:product",
      title: "Product_Name__c",
      subtitle: "Product_Cat_Code__c",
      selectedIds: null
    })
      .then((results) => {
        this.template
          .querySelector('c-lookup[data-index="' + index + '"]')
          .setSearchResults(results);
      })
      .catch((error) => {
        //this.notifyUser('Lookup Error', 'An error occured while searching with the lookup field.', 'error');
        // eslint-disable-next-line no-console
        console.error("Lookup error", JSON.stringify(error));
        this.errors = [error];
      });
  }

  handleSelectionChange(event) {
    console.log("handleSelectionChange");
    console.log(event.target.dataset.index);
    console.log(event.detail[0]);
    this.add7Default = false;
    let pricebook2Id = this.order.data.fields.Pricebook2Id.value;
    let Customer_Category = this.order.data.fields.Price_List_Type__c.value;
    let createdDate = this.order.data.fields.CreatedDate.value;

    this.items.forEach((item) => {
      if (item.index == event.target.dataset.index) {
        if (typeof event.detail[0] !== "undefined") {
          item.Product2Id = event.detail[0];
          testgetPickListValues1({
            productId: item.Product2Id,
            wareHouseCode: this.wareHouseCode,
            createdDate: createdDate
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
                    if (mapitem.value.length == 1) {
                      var mapitemJSON = JSON.stringify(mapitem.value);
                      var obj = JSON.parse(mapitemJSON);
                      item.selectedOption = obj[0].value;
                      item.UOM__c = item.selectedOption;
                      console.log('selectedOption ' + item.selectedOption);
                    }
                  }
                });

                if (typeof item.selectedOption !== "undefined") {
                  query({
                    q: 'SELECT Id, List_Price__c, Cost_Price__c, Dealer_List_Price__c, Dealer_Price_Discount__c, Maximum_End_User_Discount__c, Max_Dealer_Price_Discount__c FROM Pansar_Product__c WHERE Product__c = \'' +
                      item.Product2Id + '\' AND Warehouse__r.code__c = \'' + this.wareHouseCode + '\' AND UOM__c = \'' + item.selectedOption + '\''
                  })
                    .then((result) => {
                      if (result && result.length !== 0) {
                        console.log(result);
                        result.map((i) => {
                          if (this.order.data.fields.Indent_Sales__c.value == true && this.isSalesPerson == true) {
                            item.Cost_Price__c = 0;
                          }
                          else item.Cost_Price__c = i.Cost_Price__c;

                          if (Customer_Category == 'Dealer') {
                            item.ListPrice = i.Dealer_List_Price__c;
                          }
                          else {
                            item.ListPrice = i.List_Price__c;
                          }

                          item.Margin__c = null;
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
                  item.PricebookEntryId = i.Id;
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
        } else {
          item.Product2Id = null;
          item.Product2 = {};
          item.UnitPrice = null;
          item.Quantity = null;
          item.TotalPrice = null;
          item.Discount = 0;
          item.Cost_Price__c = 0;
          item.ListPrice = null;
          item.Margin__c = null;
          item.Quantity_Remaining__c = null;
          item.Options = null;
          item.Description2__c = null;
          item.selectedOption = null;
          item.UOM__c = null;
          //item.errors = [{id: "1", message: "Complete this field."}];
        }
      }
    });
  }

  saveProducts(event) {
    console.log("saveProducts");
    let close = event.target.dataset.close;
    this.showSpinner = true;
    let allValid = [
      ...this.template.querySelectorAll("lightning-input")
    ].reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);

    let validPicklist = [
      ...this.template.querySelectorAll("lightning-combobox")
    ].reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true)

    if (allValid && validPicklist) {
      let sobjs = this.items.map((item) => {
        console.log("allValid : " + item.Product2Id);
        console.log("item.Margin__c : " + item.Margin__c);
        console.log("item.Cost_Price__c : " + item.Cost_Price__c);
        console.log("item.Discount : " + item.Discount);
        if (item.Product2Id && typeof item.Product2Id != "undefined") {
          let sobj = {};
          sobj.Quantity = parseFloat(item.Quantity);
          sobj.UnitPrice = parseFloat(item.UnitPrice);
          sobj.Margin__c = item.Margin__c;
          sobj.Cost_Price__c = parseFloat(item.Cost_Price__c);
          sobj.Discount__c = item.Discount;
          sobj.Product2Id = item.Product2Id;
          sobj.UOM__c = item.UOM__c;
          sobj.List_Price__c = item.ListPrice;
          sobj.Total_Price_Discount__c = item.TotalPrice;
          console.log("Total_Price_Discount__c : " + sobj.Total_Price_Discount__c);

          if (item.isNew) {
            sobj.sobjectType = 'OrderItem';
            sobj.PricebookEntryId = item.PricebookEntryId;
            sobj.OrderId = item.OrderId;
          } else {
            sobj.Id = item.Id;
          }

          console.log("sobj : " + sobj);
          return sobj;
        }
      });

      let newProducts = [];
      console.log(JSON.parse(JSON.stringify(this.newItems)));
      this.newItems.forEach(item => {
        let newProductClass = {};
        if (item.Product2.Name && typeof item.Product2.Name != "undefined" &&
          item.Product2.ProductCode && typeof item.Product2.ProductCode != "undefined") {
          newProductClass.newProduct = item.Product2;
          console.log(JSON.parse(JSON.stringify(newProductClass.newProduct)));

          let oppProduct = {};
          oppProduct.Quantity = parseFloat(item.Quantity);
          oppProduct.UnitPrice = parseFloat(item.UnitPrice);
          oppProduct.Margin__c = item.Margin__c;
          oppProduct.Cost_Price__c = parseFloat(item.Cost_Price__c);
          oppProduct.Discount__c = item.Discount;
          oppProduct.UOM__c = item.Product2.UOM__c;
          oppProduct.List_Price__c = item.ListPrice;
          oppProduct.Total_Price_Discount__c = item.TotalPrice;
          oppProduct.sobjectType = "OrderItem";
          oppProduct.OrderId = item.OrderId;

          newProductClass.oppProduct = oppProduct;
          console.log(newProductClass);
        }
        newProducts.push(newProductClass);
        console.log(newProducts);
      });

      saveAndDelete({ lineItems: sobjs, deleteLineItems: this.removedItems, orderId: this.recordId, newProducts: newProducts })
        .then((result) => {
          if (close == 'true') {
            const closeQA = new CustomEvent('close');
            this.dispatchEvent(closeQA);
          }
          else {
            this.showSpinner = false;
            this.queryUOMs();
            this.removedItems = [];
            this.newItems = [];
          }
        })
        .catch((error) => {
          this.showSpinner = false;
          console.log("Error in save: " + JSON.stringify(error.body.message));
          showToast(this, "error", "Error!", JSON.stringify(error.body.message));
        });
    } else {
      this.showSpinner = false;
    }
  }
}