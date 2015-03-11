//
//  MDJSONModel.swift
//  MDJSONModel
//
//  Created by xuehan on 15/3/11.
//  Copyright (c) 2015年 xuehan. All rights reserved.
//

import Foundation

@objc protocol DictModelProtocle{
    
    // 自定义类映射  -> [属性名：自定义类]
    static func customeClassMapping()->[String:String]?
    
}
class SwiftDictModel{
    
    ///  将字典转为模型
    ///
    ///  :param: dict 将要转换得字典
    ///  :param: cls  要转换成的模型
    ///
    ///  :returns: 经过转换后的字典模型
    func objectWithDict(dict:NSDictionary,cls:AnyClass)->AnyObject?{
        
        // 获取模型属性字典
        let modelDict = fullModelInfo(cls)
        // 给模型属性赋值
        var obj:AnyObject = cls.alloc()
        for (k,v) in modelDict{
            if let value:AnyObject? = dict[k]{
                if v.isEmpty && !(value === NSNull()){
                    
                    obj.setValue(value, forKey: k)
                    
                }else{
                    
                    let type = "\(value!.classForCoder)"
                    
                    if type == "NSDictionary"{
                        
                        if let subObj:AnyObject? = objectWithDict(value as! NSDictionary, cls: NSClassFromString(v)){
                            
                            obj.setValue(subObj, forKey:k)
                        }
                    }else if type == "NSArray" {
                        if let subObj:AnyObject? = objectWithArray(value as! NSArray, cls: NSClassFromString(v)){
                            obj.setValue(subObj, forKey: k)
                            
                        }
                    }
                }
            }
        }
        // 返回对象
        return obj
    }
    ///  数组转模型字典
    ///
    ///  :param: array 要转的数组
    ///  :param: cls   要转成的模型
    ///
    ///  :returns: 模型
    func objectWithArray(array:NSArray,cls:AnyClass)->[AnyObject]?{
        
        // 创建数组
        var result = [AnyObject]()
        
        // 遍历数组,进行模型转换
        for value in array{
            let type = "\(value.classForCoder)"
            if type == "NSDictionary"{
                if let obj: AnyObject = objectWithDict(value as! NSDictionary, cls: cls){
                    result.append(obj)
                }
            }else if type == "NSArray" {
                if let obj:AnyObject = objectWithArray(value as! NSArray, cls: cls){
                    result.append(obj)
                }
            }
        }
        // 返回结果
        return result
    }
    // 模型缓存池，存放已经转过的模型
    var dictCache = [String:AnyObject]()
    
    // 获取类的全部属性信息，包含父类
    func fullModelInfo(cls:AnyClass)->[String:String]{
        
        // 如果已经转换过，就不用要再次转换
        if let cache: AnyObject = dictCache["\(cls)"]{
            
            println("\(cls)已经缓存过了")
            return cache as! [String : String]
        }
        
        var dictInfo = [String:String]()
        var currentClass: AnyClass = cls
        while let parent: AnyClass = currentClass.superclass(){
            dictInfo.merge(modelInfo(currentClass))
            currentClass = parent
        }
        
        dictCache["\(cls)"] = dictInfo
        return dictInfo
    }
    
    
    // 获取给定类的信息
    func modelInfo(cls:AnyClass)->[String:String]{
        
        // 如果已经转换过，就不用要再次转换
        if let cache: AnyObject = dictCache["\(cls)"]{
            
            println("\(cls)已经缓存过了")
            return cache as! [String : String]
        }
        
        // 1、获得属性字典
        var count:UInt32 = 0
        let ivars = class_copyIvarList(cls, &count)
        
        // 2、获得自定义类型
        var dict : [String:String]?
        if cls.respondsToSelector("customeClassMapping"){
            dict  =  cls.customeClassMapping()
        }
        // 3、拼接成字典
        var dictInfo = [String:String]()
        for i in 0..<count{
            let ivar = ivars[Int(i)]
            let cname = ivar_getName(ivar)
            let name = String.fromCString(cname)!
            let type = dict?[name] ?? ""
            dictInfo[name] = type
        }
        free(ivars)
        
        dictCache["\(cls)"] = dictInfo
        // 4、返回属性字典
        return dictInfo
    }
    
}

extension Dictionary{
    // 字典拼接
    mutating func merge<K,V>(dict:[K:V]){
        for (k,v) in dict{
            self.updateValue(v as! Value, forKey: k as! Key)
        }
    }
}
