using do_SlideView.extdefine;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using doCore.Helper.JsonParse;
using doCore.Interface;
using doCore.Object;


namespace do_SlideView.extimplement
{
    /// <summary>
    /// 自定义扩展组件Model实现，继承@TYPEID_MAbstract抽象类；
    /// </summary>
    public class do_SlideView_Model : do_SlideView_MAbstract
    {
        public do_SlideView_Model():base()
        {

        }
        public override void OnInit()
        {
            base.OnInit();
            //注册属性

        }
        //处理成员方法
        public override bool InvokeSyncMethod(string _methodName, doJsonNode _dictParas,
            doIScriptEngine _scriptEngine, doInvokeResult _invokeResult)
        {
            if (base.InvokeSyncMethod(_methodName, _dictParas, _scriptEngine, _invokeResult)) return true;


            return false;
        }

        public override async Task<bool> InvokeAsyncMethod(string _methodName, doJsonNode _dictParas,
            doIScriptEngine _scriptEngine, string _callbackFuncName)
        {
            if (await base.InvokeAsyncMethod(_methodName, _dictParas, _scriptEngine, _callbackFuncName)) return true;

            return false;
        }
    }
}
