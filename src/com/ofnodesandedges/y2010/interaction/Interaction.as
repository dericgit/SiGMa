/**
 *
 * SiGMa, the Simple Graph Mapper
 * Copyright (C) 2010, Alexis Jacomy
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

package com.ofnodesandedges.y2010.interaction{
	
	import com.ofnodesandedges.y2010.graphics.GraphGraphics;
	import com.ofnodesandedges.y2010.graphics.MainDisplayElement;
	import com.ofnodesandedges.y2010.graphics.NodeGraphics;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	public class Interaction extends EventDispatcher{
		
		public static const MOVING_STEP:Number = 15;
		public static const ZOOMING_STEP:Number = 2;
		
		public static const CLICK_NODE:String = "click node";
		public static const CLICK_STAGE:String = "click stage";
		
		public static const ZOOM_RATIO:Number = 1.5;
		public static const ZOOM_SPEED:Number = 3/4;
		public static const CLICK_TIME:uint = 250;
		
		private var _graphGraphics:GraphGraphics;
		
		private var _sprite:Sprite;
		private var _ratio:Number;
		private var _x:Number;
		private var _y:Number;
		
		private var _tempX:Number;
		private var _tempY:Number;
		private var _mouseX:Number;
		private var _mouseY:Number;
		private var _zoomRatio:Number;
		
		private var _clickTime:uint;
		private var _isMouseDown:Boolean
		
		private var _clickedNodeID:String;
		
		public function Interaction(sprite:Sprite, graphGraphics:GraphGraphics){
			_graphGraphics = graphGraphics;
			_sprite = sprite;
			
			_sprite.graphics.beginFill(0xFFAA55,0);
			_sprite.graphics.drawRect(-10,-10,_sprite.stage.stageWidth+20,_sprite.stage.stageHeight+20);
			_sprite.graphics.endFill();
			
			_sprite.stage.addEventListener(Event.RESIZE,onScreenRescaling);
			resetValues();
		}
		
		public function backToGlobalView():void{
			_clickedNodeID = null;
			dispatchEvent(new Event(CLICK_STAGE));
		}
		
		public function selectRandomNode():void{
			var index:int = Math.floor(_graphGraphics.nodes.length*Math.random());
			var node:NodeGraphics = _graphGraphics.nodes[index];
			
			_clickedNodeID = node.id;
			dispatchEvent(new Event(CLICK_NODE));
		}
		
		private function mouseDown(m:MouseEvent):void{
			_tempX = _x;
			_tempY = _y;
			_clickTime = getTimer();
			
			_isMouseDown = true;
		}
		
		private function mouseUp(m:MouseEvent):void{
			_isMouseDown = false;
			
			if(getTimer() - _clickTime<CLICK_TIME){
				click();
			}
		}
		
		private function mouseWheel(m:MouseEvent):void{
			_mouseX = m.stageX;
			_mouseY = m.stageY;
			
			if(m.delta>=0){
				startZoomIn();
			}else{
				startZoomOut();
			}
		}
		
		private function mouseMove(m:MouseEvent):void{
			if(_isMouseDown){
				_x = m.stageX - _mouseX + _tempX;
				_y = m.stageY - _mouseY + _tempY;
			}else{
				_mouseX = m.stageX;
				_mouseY = m.stageY;
			}
		}
		
		private function click():void{
			// Check if it clicks on a node:
			var node:NodeGraphics = null;
			
			for each(var parser:NodeGraphics in _graphGraphics.nodes){
				var dist:Number = Math.sqrt(Math.pow(_mouseX-parser.displayX,2)+Math.pow(_mouseY-parser.displayY,2));
				
				if(dist<parser.displaySize){
					node = parser;
					break;
				}
			}
			
			if(node){
				// If clicks a node:
				_clickedNodeID = node.id;
				dispatchEvent(new Event(CLICK_NODE));
			}else{
				// If clicks the stage:
				
			}
		}
		
		private function startZoomIn():void{
			_zoomRatio = ZOOM_RATIO*_ratio;
			_sprite.stage.addEventListener(Event.ENTER_FRAME,zoomIn);
			_sprite.stage.removeEventListener(Event.ENTER_FRAME,zoomOut);
		}
		
		private function startZoomOut():void{
			_zoomRatio = _ratio/ZOOM_RATIO;
			_sprite.stage.addEventListener(Event.ENTER_FRAME,zoomOut);
			_sprite.stage.removeEventListener(Event.ENTER_FRAME,zoomIn);
		}
		
		private function zoomIn(e:Event):void{
			if(_zoomRatio/_ratio>1.05){
				var new_ratio:Number = _ratio*(1-ZOOM_SPEED) + _zoomRatio*ZOOM_SPEED;
				_x = _mouseX+(_x-_mouseX)*new_ratio/_ratio;
				_y = _mouseY+(_y-_mouseY)*new_ratio/_ratio;
				_ratio = new_ratio;
			}else{
				_sprite.stage.removeEventListener(Event.ENTER_FRAME,zoomIn);
			}
		}
		
		private function zoomOut(e:Event):void{
			if(_ratio/_zoomRatio>1.05){
				var new_ratio:Number = _ratio*(1-ZOOM_SPEED) + _zoomRatio*ZOOM_SPEED;
				_x = _mouseX+(_x-_mouseX)*new_ratio/_ratio;
				_y = _mouseY+(_y-_mouseY)*new_ratio/_ratio;
				_ratio = new_ratio;
			}else{
				_sprite.stage.removeEventListener(Event.ENTER_FRAME,zoomOut);
			}
		}
		
		public function mouseOverNode():void{
			for each(var node:NodeGraphics in _graphGraphics.nodes){
				var dist:Number = Math.sqrt(Math.pow(_mouseX-node.displayX,2)+Math.pow(_mouseY-node.displayY,2));
				
				if(dist<node.displaySize){
					node.displaySize *= 1.2;
					node.borderThickness = node.displaySize/3;
					
					node.stopped = true;
				}else{
					node.stopped = false;
				}
			}
		}
		
		public function applyValues(ratio:Number):void{
			for each(var node:NodeGraphics in _graphGraphics.nodes){
				node.displaySize *= Math.sqrt(ratio);
				node.borderThickness *= Math.sqrt(ratio);
			}
		}
		
		public function enable():void{
			_sprite.addEventListener(MouseEvent.MOUSE_DOWN,mouseDown);
			_sprite.addEventListener(MouseEvent.MOUSE_UP,mouseUp);
			_sprite.addEventListener(MouseEvent.MOUSE_WHEEL,mouseWheel);
			_sprite.addEventListener(MouseEvent.MOUSE_MOVE,mouseMove);
			_sprite.stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownHandler);
		}
		
		public function disable():void{
			_sprite.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDown);
			_sprite.removeEventListener(MouseEvent.MOUSE_UP,mouseUp);
			_sprite.removeEventListener(MouseEvent.MOUSE_WHEEL,mouseWheel);
			_sprite.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMove);
			_sprite.stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownHandler);
		}
		
		public function resetValues():void{
			_x = 0;
			_y = 0;
			_ratio = 1;
			
			_sprite.stage.removeEventListener(Event.ENTER_FRAME,zoomIn);
			_sprite.stage.removeEventListener(Event.ENTER_FRAME,zoomOut);
			_sprite.stage.removeEventListener(Event.ENTER_FRAME,mouseMove);
		}
		
		private function keyDownHandler(k:KeyboardEvent):void{
			switch(k.keyCode){
				case Keyboard.LEFT:
					_x += MOVING_STEP;
					break;
				case Keyboard.RIGHT:
					_x -= MOVING_STEP;
					break;
				case Keyboard.UP:
					_y += MOVING_STEP;
					break;
				case Keyboard.DOWN:
					_y -= MOVING_STEP;
					break;
				case Keyboard.SPACE:
					resetValues();
					break;
				case Keyboard.PAGE_UP:
				case "187": // Plus
					_ratio *= ZOOMING_STEP;
					break;
				case Keyboard.PAGE_DOWN:
				case "189": // Minus
					_ratio /= ZOOMING_STEP;
					break;
				default:
					break;
			}
		}
		
		private function onScreenRescaling(e:Event):void{
			_sprite.graphics.beginFill(0xFFAA55,0);
			_sprite.graphics.drawRect(-10,-10,_sprite.stage.stageWidth+20,_sprite.stage.stageHeight+20);
			_sprite.graphics.endFill();
		}
		
		public function get ratio():Number{
			return _ratio;
		}
		
		public function get x():Number{
			return _x;
		}
		
		public function get y():Number{
			return _y;
		}
		
		public function get clickedNodeID():String{
			return _clickedNodeID;
		}
		
	}
}