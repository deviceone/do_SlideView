package doext.implement;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import android.annotation.SuppressLint;
import android.content.Context;
import android.support.v4.view.PagerAdapter;
import android.support.v4.view.ViewPager;
import android.view.View;
import android.view.ViewGroup;
import core.DoServiceContainer;
import core.helper.DoTextHelper;
import core.helper.DoUIModuleHelper;
import core.helper.jsonparse.DoJsonNode;
import core.helper.jsonparse.DoJsonValue;
import core.interfaces.DoIListData;
import core.interfaces.DoIScriptEngine;
import core.interfaces.DoIUIModuleView;
import core.object.DoInvokeResult;
import core.object.DoSourceFile;
import core.object.DoUIContainer;
import core.object.DoUIModule;
import doext.define.do_SlideView_IMethod;
import doext.define.do_SlideView_MAbstract;

/**
 * 自定义扩展UIView组件实现类，此类必须继承相应VIEW类，并实现DoIUIModuleView,do_SlideView_IMethod接口；
 * #如何调用组件自定义事件？可以通过如下方法触发事件：
 * this.model.getEventCenter().fireEvent(_messageName, jsonResult);
 * 参数解释：@_messageName字符串事件名称，@jsonResult传递事件参数对象；
 * 获取DoInvokeResult对象方式new DoInvokeResult(this.getUniqueKey());
 */
public class do_SlideView_View extends ViewPager implements DoIUIModuleView, do_SlideView_IMethod{
	
	/**
	 * 每个UIview都会引用一个具体的model实例；
	 */
	private do_SlideView_MAbstract model;
	private boolean isLooping = false;
	private String[] templates;

	public do_SlideView_View(Context context) {
		super(context);
	}
	
	/**
	 * 初始化加载view准备,_doUIModule是对应当前UIView的model实例
	 */
	@Override
	public void loadView(DoUIModule _doUIModule) throws Exception {
		this.model = (do_SlideView_MAbstract)_doUIModule;
		this.setOnPageChangeListener(new MyPageChangeListener());
	}
	
	/**
	 * 动态修改属性值时会被调用，方法返回值为true表示赋值有效，并执行onPropertiesChanged，否则不进行赋值；
	 * @_changedValues<key,value>属性集（key名称、value值）；
	 */
	@Override
	public boolean onPropertiesChanging(Map<String, String> _changedValues) {
		if (_changedValues.containsKey("templates")) {
			String value = _changedValues.get("templates");
			if ("".equals(value)) {
				return false;
			}
		}
		return true;
	}
	
	/**
	 * 属性赋值成功后被调用，可以根据组件定义相关属性值修改UIView可视化操作；
	 * @_changedValues<key,value>属性集（key名称、value值）；
	 */
	@Override
	public void onPropertiesChanged(Map<String, String> _changedValues) {
		DoUIModuleHelper.handleBasicViewProperChanged(this.model, _changedValues);
		if (_changedValues.containsKey("templates")) {
			initViewTemplate(_changedValues.get("templates"));
		}
		if (_changedValues.containsKey("index")) {
			int item = DoTextHelper.strToInt(_changedValues.get("index"), 0);
			this.setCurrentItem(item, false);
		}
		if (_changedValues.containsKey("looping")) {
			isLooping = DoTextHelper.strToBool(_changedValues.get("looping"), false);
		}
	}
	
	private void initViewTemplate(String data) {
		try {
			templates = data.split(",");
		} catch (Exception e) {
			DoServiceContainer.getLogEngine().writeError("解析templates错误： \t", e);
		}
	}
	
	/**
	 * 同步方法，JS脚本调用该组件对象方法时会被调用，可以根据_methodName调用相应的接口实现方法；
	 * @_methodName 方法名称
	 * @_dictParas 参数（K,V）
	 * @_scriptEngine 当前Page JS上下文环境对象
	 * @_invokeResult 用于返回方法结果对象
	 */
	@Override
	public boolean invokeSyncMethod(String _methodName, DoJsonNode _dictParas,
			DoIScriptEngine _scriptEngine, DoInvokeResult _invokeResult)throws Exception {
		//...do something
		return false;
	}
	
	/**
	 * 异步方法（通常都处理些耗时操作，避免UI线程阻塞），JS脚本调用该组件对象方法时会被调用，
	 * 可以根据_methodName调用相应的接口实现方法；
	 * @_methodName 方法名称
	 * @_dictParas 参数（K,V）
	 * @_scriptEngine 当前page JS上下文环境
	 * @_callbackFuncName 回调函数名
	 * #如何执行异步方法回调？可以通过如下方法：
	 *	_scriptEngine.callback(_callbackFuncName, _invokeResult);
	 * 参数解释：@_callbackFuncName回调函数名，@_invokeResult传递回调函数参数对象；
	   获取DoInvokeResult对象方式new DoInvokeResult(this.getUniqueKey());
	 */
	@Override
	public boolean invokeAsyncMethod(String _methodName, DoJsonNode _dictParas,
			DoIScriptEngine _scriptEngine, String _callbackFuncName) {
		//...do something
		return false;
	}
	
	/**
	* 释放资源处理，前端JS脚本调用closePage或执行removeui时会被调用；
	*/
	@Override
	public void onDispose() {
		//...do something
	}
	
	/**
	* 重绘组件，构造组件时由系统框架自动调用；
	  或者由前端JS脚本调用组件onRedraw方法时被调用（注：通常是需要动态改变组件（X、Y、Width、Height）属性时手动调用）
	*/
	@Override
	public void onRedraw() {
		this.setLayoutParams(DoUIModuleHelper.getLayoutParams(this.model));
	}
	
	class MyPagerAdapter extends PagerAdapter{
		
		@SuppressLint("UseSparseArrays")
		private Map<Integer,View> viewMap = new HashMap<Integer,View>();
		private Map<String, String> itemTemplates = new HashMap<String, String>();
		private List<String> uiTemplates = new ArrayList<String>();
		private Object data;
		
		public void bindData(DoIListData listData) {
			if(listData.getCount() > 1 && isLooping){
				List<Object> loopData = new ArrayList<Object>();
				Object lastData = listData.getData(listData.getCount()-1);
				Object firstData = listData.getData(0);
				loopData.add(lastData);
				for(int i=0; i<listData.getCount(); i++){
					loopData.add(listData.getData(i));
				}
				loopData.add(firstData);
				this.data = loopData;
				isLooping = true;
				return;
			}
			this.data = listData;
		}
		
		public void initTemplates(String[] templates) throws Exception {
			uiTemplates.clear();
			for (String templatePath : templates) {
				if (templatePath != null && !templatePath.equals("")) {
					DoSourceFile _sourceFile = model.getCurrentPage().getCurrentApp().getSourceFS().getSourceByFileName(templatePath);
					if (_sourceFile != null) {
						itemTemplates.put(templatePath, _sourceFile.getTxtContent());
						uiTemplates.add(templatePath);
					} else {
						throw new RuntimeException("试图使用一个无效的UI页面:" + templatePath);
					}
				}
			}
		}
		
		@Override
		public void destroyItem(ViewGroup container, int position, Object object) {
			container.removeView(viewMap.get(position));
		}

		@Override
		public Object instantiateItem(ViewGroup container, int position) {
			try {
				DoJsonValue childData = null;
				if(data instanceof DoIListData){
					childData = (DoJsonValue) ((DoIListData)data).getData(position);
				}else{
					childData = (DoJsonValue) ((List<?>)data).get(position);
				}
				int _index = DoTextHelper.strToInt(childData.getNode().getOneText("template", "0"), 0);
				String uiTemplate = uiTemplates.get(_index);
				if (uiTemplate == null) {
					throw new RuntimeException("绑定一个无效的模版Index值");
				}
				DoIUIModuleView _doIUIModuleView = null;
				if (viewMap.get(position) == null) {
					String content = itemTemplates.get(uiTemplate);
					DoUIContainer _doUIContainer = new DoUIContainer(model.getCurrentPage());
					_doUIContainer.loadFromContent(content, null, null);
					_doUIContainer.loadDefalutScriptFile(uiTemplate);
					_doIUIModuleView = _doUIContainer.getRootView().getCurrentUIModuleView();
					viewMap.put(position, (View) _doIUIModuleView);
				} else {
					_doIUIModuleView = (DoIUIModuleView) viewMap.get(position);
				}
				_doIUIModuleView.getModel().setModelData(null, childData);
				container.addView((View) _doIUIModuleView);
			} catch (Exception e) {
				DoServiceContainer.getLogEngine().writeError("解析data数据错误： \t",
						e);
			}
			return position;
		}
		
		@Override
		public int getCount() {
			if (data == null) {
				return 0;
			}
			if(data instanceof DoIListData){
				return ((DoIListData) data).getCount();
			}
			return ((List<?>)data).size();
		}

		@Override
		public boolean isViewFromObject(View arg0, Object arg1) {
			return arg0 == viewMap.get((int)Integer.parseInt(arg1.toString())); 
		}
		
	}
	
	class MyPageChangeListener implements ViewPager.OnPageChangeListener{

		@Override
		public void onPageScrollStateChanged(int arg0) {
			
		}

		@Override
		public void onPageScrolled(int arg0, float arg1, int arg2) {
			
		}

		@Override
		public void onPageSelected(int position) {
			int index = position;
			if (isLooping) {
				int count = getAdapter().getCount() - 2;
				if (position < 1) { // 首位之前，跳转到末尾（N）
					index = count;
					setCurrentItem(index, false);
				} else if (position > count) { // 末位之后，跳转到首位（1）
					index = 1;
					setCurrentItem(index, false); // false:不显示跳转过程的动画
				}
			}
			DoInvokeResult invokeResult = new DoInvokeResult(model.getUniqueKey());
			invokeResult.setResultInteger(index);
			model.getEventCenter().fireEvent("indexChanged", invokeResult);
		}
	}
	
	public void setModelData(Object _obj) {
		if (_obj == null)
			return;
		if (_obj instanceof DoIListData) {
			DoIListData _listData = (DoIListData) _obj;
			MyPagerAdapter mPagerAdapter = new MyPagerAdapter();
			try{
				mPagerAdapter.initTemplates(templates);
			} catch (Exception e) {
				DoServiceContainer.getLogEngine().writeError("解析templates错误： \t", e);
				return;
			}
			mPagerAdapter.bindData(_listData);
			this.setAdapter(mPagerAdapter);
			if(isLooping){
				this.setCurrentItem(1);
			}
		}
	}
	
	/**
	 * 获取当前model实例
	 */
	@Override
	public DoUIModule getModel() {
		return model;
	}


}